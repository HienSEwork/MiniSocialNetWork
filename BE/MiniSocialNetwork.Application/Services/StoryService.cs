using MiniSocialNetwork.Application.DTOs.Story;
using MiniSocialNetwork.Application.Interfaces;
using MiniSocialNetwork.Application.Interfaces.Repositories;
using MiniSocialNetwork.Domain.Entities;

namespace MiniSocialNetwork.Application.Services;

public sealed class StoryService : IStoryService
{
    private readonly IStoryRepository _storyRepository;
    private readonly IContentFilter _contentFilter;

    public StoryService(IStoryRepository storyRepository, IContentFilter contentFilter)
    {
        _storyRepository = storyRepository;
        _contentFilter = contentFilter;
    }

    public async Task<List<StoryResponse>> GetActiveAsync(string userId)
        => (await _storyRepository.GetActiveAsync()).Select(story => Map(story, userId)).ToList();

    public async Task<StoryResponse> GetByIdAsync(Guid id, string userId)
    {
        var story = await _storyRepository.GetByIdAsync(id);
        if (story == null || story.IsDeleted || story.ExpiresAt <= DateTime.UtcNow)
            throw new KeyNotFoundException("Story not found");
        return Map(story, userId);
    }

    public async Task<Guid> CreateAsync(CreateStoryRequest request, string userId)
    {
        Validate(request);
        var story = new Story
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Content = request.Content.Trim(),
            MediaUrl = string.IsNullOrWhiteSpace(request.MediaUrl) ? null : request.MediaUrl.Trim(),
            MediaType = string.IsNullOrWhiteSpace(request.MediaUrl) ? 0 : request.MediaType,
            CreatedDate = DateTime.UtcNow,
            ExpiresAt = DateTime.UtcNow.AddHours(24),
            IsDeleted = false
        };
        await _storyRepository.AddAsync(story);
        await _storyRepository.SaveChangesAsync();
        return story.Id;
    }

    public async Task UpdateAsync(Guid id, CreateStoryRequest request, string userId)
    {
        Validate(request);
        var story = await GetOwnedStoryAsync(id, userId);
        story.Content = request.Content.Trim();
        story.MediaUrl = string.IsNullOrWhiteSpace(request.MediaUrl) ? null : request.MediaUrl.Trim();
        story.MediaType = string.IsNullOrWhiteSpace(request.MediaUrl) ? 0 : request.MediaType;
        story.UpdatedDate = DateTime.UtcNow;
        await _storyRepository.SaveChangesAsync();
    }

    public async Task DeleteAsync(Guid id, string userId)
    {
        var story = await GetOwnedStoryAsync(id, userId);
        story.IsDeleted = true;
        story.UpdatedDate = DateTime.UtcNow;
        await _storyRepository.SaveChangesAsync();
    }

    public async Task<StoryResponse> ReactAsync(Guid id, int type, string userId)
    {
        if (type < 1 || type > 6) throw new ArgumentException("Reaction type is not supported");
        var story = await _storyRepository.GetByIdAsync(id);
        if (story == null || story.IsDeleted || story.ExpiresAt <= DateTime.UtcNow)
            throw new KeyNotFoundException("Story not found");

        var reaction = await _storyRepository.GetReactionAsync(id, userId);
        if (reaction == null)
        {
            await _storyRepository.AddReactionAsync(new StoryReaction
            {
                Id = Guid.NewGuid(),
                StoryId = id,
                UserId = userId,
                Type = type,
                CreatedDate = DateTime.UtcNow
            });
        }
        else if (reaction.Type == type)
        {
            _storyRepository.RemoveReaction(reaction);
        }
        else
        {
            reaction.Type = type;
            reaction.UpdatedDate = DateTime.UtcNow;
        }

        await _storyRepository.SaveChangesAsync();
        story = await _storyRepository.GetByIdAsync(id) ?? story;
        return Map(story, userId);
    }

    public async Task<string> GetAuthorIdAsync(Guid id)
    {
        var story = await _storyRepository.GetByIdAsync(id);
        if (story == null || story.IsDeleted || story.ExpiresAt <= DateTime.UtcNow)
            throw new KeyNotFoundException("Story not found");
        return story.UserId;
    }

    private async Task<Story> GetOwnedStoryAsync(Guid id, string userId)
    {
        var story = await _storyRepository.GetByIdAsync(id);
        if (story == null || story.IsDeleted || story.ExpiresAt <= DateTime.UtcNow)
            throw new KeyNotFoundException("Story not found");
        if (story.UserId != userId)
            throw new UnauthorizedAccessException("Only the author can modify this story");
        return story;
    }

    private void Validate(CreateStoryRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Content) && string.IsNullOrWhiteSpace(request.MediaUrl))
            throw new ArgumentException("Story must have content or media");
        if (request.Content.Length > 320)
            throw new ArgumentException("Story content is too long");
        if (!_contentFilter.IsAllowed(request.Content))
            throw new ArgumentException("Story content violates community safety rules");
    }

    private static StoryResponse Map(Story story, string userId) => new()
    {
        Id = story.Id,
        UserId = story.UserId,
        AuthorName = story.User?.DisplayName ?? "Member",
        AuthorAvatarUrl = story.User?.AvatarUrl,
        Content = story.Content,
        MediaUrl = story.MediaUrl,
        MediaType = story.MediaType,
        CreatedDate = story.CreatedDate,
        ExpiresAt = story.ExpiresAt,
        UpdatedDate = story.UpdatedDate,
        ReactionCount = story.Reactions?.Count ?? 0,
        CurrentUserReaction = story.Reactions?.FirstOrDefault(reaction => reaction.UserId == userId)?.Type,
        ReactionCounts = story.Reactions?.GroupBy(reaction => reaction.Type)
            .ToDictionary(group => group.Key, group => group.Count())
            ?? new Dictionary<int, int>()
    };
}
