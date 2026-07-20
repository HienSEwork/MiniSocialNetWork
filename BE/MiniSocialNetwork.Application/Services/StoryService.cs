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

    public async Task<List<StoryResponse>> GetActiveAsync()
        => (await _storyRepository.GetActiveAsync()).Select(Map).ToList();

    public async Task<StoryResponse> GetByIdAsync(Guid id)
    {
        var story = await _storyRepository.GetByIdAsync(id);
        if (story == null || story.IsDeleted || story.ExpiresAt <= DateTime.UtcNow)
            throw new KeyNotFoundException("Story not found");
        return Map(story);
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

    private static StoryResponse Map(Story story) => new()
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
        UpdatedDate = story.UpdatedDate
    };
}
