using MiniSocialNetwork.Application.DTOs.Reaction;
using MiniSocialNetwork.Application.Interfaces;
using MiniSocialNetwork.Application.Interfaces.Repositories;
using MiniSocialNetwork.Domain.Entities;

namespace MiniSocialNetwork.Application.Services;

public sealed class ReactionService : IReactionService
{
    private readonly IReactionRepository _reactionRepository;
    private readonly IPostRepository _postRepository;
    private readonly IRealtimeNotifier _notifier;

    public ReactionService(IReactionRepository reactionRepository, IPostRepository postRepository, IRealtimeNotifier notifier)
    {
        _reactionRepository = reactionRepository;
        _postRepository = postRepository;
        _notifier = notifier;
    }

    public async Task<ReactionSummaryResponse> GetSummaryAsync(Guid postId, string? userId)
    {
        await EnsurePostExistsAsync(postId);
        return await BuildSummaryAsync(postId, userId);
    }

    public async Task<ReactionSummaryResponse> ToggleAsync(Guid postId, int type, string userId)
    {
        if (type is < 1 or > 3) throw new ArgumentException("Reaction type must be Like (1), Love (2), or Haha (3)");
        var post = await EnsurePostExistsAsync(postId);
        var current = await _reactionRepository.GetUserReactionAsync(postId, userId);
        if (current == null)
        {
            await _reactionRepository.AddAsync(new Reaction
            {
                Id = Guid.NewGuid(), PostId = postId, UserId = userId, Type = type, CreatedDate = DateTime.UtcNow
            });
        }
        else if (current.Type == type)
        {
            _reactionRepository.Remove(current);
        }
        else
        {
            current.Type = type;
            current.CreatedDate = DateTime.UtcNow;
        }
        await _reactionRepository.SaveChangesAsync();
        var summary = await BuildSummaryAsync(postId, userId);
        await _notifier.ReactionChangedAsync(summary);
        if (post.UserId != userId)
            await _notifier.NotifyUserAsync(post.UserId, new { type = "reaction", postId, reactionType = type });
        return summary;
    }

    private async Task<Post> EnsurePostExistsAsync(Guid postId)
    {
        var post = await _postRepository.GetByIdAsync(postId);
        if (post == null || post.IsDeleted) throw new KeyNotFoundException("Post not found");
        return post;
    }

    private async Task<ReactionSummaryResponse> BuildSummaryAsync(Guid postId, string? userId)
    {
        var reactions = await _reactionRepository.GetByPostAsync(postId);
        return new ReactionSummaryResponse
        {
            PostId = postId,
            Total = reactions.Count,
            Counts = reactions.GroupBy(reaction => reaction.Type).ToDictionary(group => group.Key, group => group.Count()),
            CurrentUserReaction = userId == null ? null : reactions.FirstOrDefault(reaction => reaction.UserId == userId)?.Type
        };
    }
}
