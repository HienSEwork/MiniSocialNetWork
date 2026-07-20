using MiniSocialNetwork.Application.DTOs.Comment;
using MiniSocialNetwork.Application.Interfaces;
using MiniSocialNetwork.Application.Interfaces.Repositories;
using MiniSocialNetwork.Domain.Entities;

namespace MiniSocialNetwork.Application.Services;

public sealed class CommentService : ICommentService
{
    private readonly ICommentRepository _commentRepository;
    private readonly IPostRepository _postRepository;
    private readonly IRealtimeNotifier _notifier;

    public CommentService(ICommentRepository commentRepository, IPostRepository postRepository, IRealtimeNotifier notifier)
    {
        _commentRepository = commentRepository;
        _postRepository = postRepository;
        _notifier = notifier;
    }

    public async Task<IReadOnlyCollection<CommentResponse>> GetByPostAsync(Guid postId)
    {
        await EnsurePostExistsAsync(postId);
        return (await _commentRepository.GetByPostAsync(postId)).Select(Map).ToArray();
    }

    public async Task<CommentResponse> CreateAsync(Guid postId, CommentRequest request, string userId)
    {
        var post = await EnsurePostExistsAsync(postId);
        Validate(request);
        var comment = new Comment
        {
            Id = Guid.NewGuid(),
            PostId = postId,
            UserId = userId,
            Content = request.Content.Trim(),
            CreatedDate = DateTime.UtcNow,
            IsDeleted = false
        };
        await _commentRepository.AddAsync(comment);
        await _commentRepository.SaveChangesAsync();
        if (post.UserId != userId)
            await _notifier.NotifyUserAsync(post.UserId, new { type = "comment", postId, commentId = comment.Id });
        return Map(comment);
    }

    public async Task<CommentResponse> UpdateAsync(Guid commentId, CommentRequest request, string userId)
    {
        Validate(request);
        var comment = await GetOwnedAsync(commentId, userId);
        comment.Content = request.Content.Trim();
        comment.UpdatedDate = DateTime.UtcNow;
        await _commentRepository.SaveChangesAsync();
        return Map(comment);
    }

    public async Task DeleteAsync(Guid commentId, string userId)
    {
        var comment = await GetOwnedAsync(commentId, userId);
        _commentRepository.Remove(comment);
        comment.UpdatedDate = DateTime.UtcNow;
        await _commentRepository.SaveChangesAsync();
    }

    private async Task<Post> EnsurePostExistsAsync(Guid postId)
    {
        var post = await _postRepository.GetByIdAsync(postId);
        if (post == null || post.IsDeleted) throw new KeyNotFoundException("Post not found");
        return post;
    }

    private async Task<Comment> GetOwnedAsync(Guid id, string userId)
    {
        var comment = await _commentRepository.GetByIdAsync(id);
        if (comment == null || comment.IsDeleted) throw new KeyNotFoundException("Comment not found");
        if (comment.UserId != userId) throw new UnauthorizedAccessException("Only the author can modify this comment");
        return comment;
    }

    private static void Validate(CommentRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Content)) throw new ArgumentException("Comment is required");
        if (request.Content.Length > 1000) throw new ArgumentException("Comment is too long");
    }

    private static CommentResponse Map(Comment comment) => new()
    {
        Id = comment.Id,
        PostId = comment.PostId,
        UserId = comment.UserId,
        AuthorName = comment.User?.DisplayName ?? "Member",
        AuthorAvatarUrl = comment.User?.AvatarUrl,
        Content = comment.Content,
        CreatedDate = comment.CreatedDate,
        UpdatedDate = comment.UpdatedDate
    };
}
