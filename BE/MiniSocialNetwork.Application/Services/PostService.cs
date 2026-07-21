using MiniSocialNetwork.Application.DTOs.Post;
using MiniSocialNetwork.Application.Interfaces;
using MiniSocialNetwork.Application.Interfaces.Repositories;
using MiniSocialNetwork.Domain.Entities;

namespace MiniSocialNetwork.Application.Services;

public sealed class PostService : IPostService
{
    private readonly IPostRepository _postRepository;
    private readonly IGroupRepository _groupRepository;
    private readonly IContentFilter _contentFilter;

    public PostService(IPostRepository postRepository, IGroupRepository groupRepository, IContentFilter contentFilter)
    {
        _postRepository = postRepository;
        _groupRepository = groupRepository;
        _contentFilter = contentFilter;
    }

    public async Task<Guid> CreateAsync(CreatePostRequest request, string userId)
    {
        ValidateContent(request);
        if (request.GroupId.HasValue)
            return await CreateGroupPostAsync(request.GroupId.Value, request, userId);

        var post = BuildPost(request, userId, null);
        await _postRepository.AddAsync(post);
        await _postRepository.SaveChangesAsync();
        return post.Id;
    }

    public async Task<PagedResult<PostResponse>> GetFeedAsync(PostQuery query, string userId)
        => MapPage(await _postRepository.GetFeedAsync(query, userId));

    public async Task<PostResponse> GetByIdAsync(Guid postId)
    {
        var post = await _postRepository.GetByIdAsync(postId);
        if (post == null || post.IsDeleted) throw new KeyNotFoundException("Post not found");
        return Map(post);
    }

    public async Task UpdateAsync(Guid postId, CreatePostRequest request, string userId)
    {
        ValidateContent(request);
        var post = await GetOwnedPostAsync(postId, userId);
        post.Content = request.Content.Trim();
        post.MediaUrl = string.IsNullOrWhiteSpace(request.MediaUrl) ? null : request.MediaUrl.Trim();
        post.MediaType = request.MediaType;
        post.UpdatedDate = DateTime.UtcNow;
        await _postRepository.SaveChangesAsync();
    }

    public async Task DeleteAsync(Guid postId, string userId)
    {
        var post = await GetOwnedPostAsync(postId, userId);
        post.IsDeleted = true;
        post.UpdatedDate = DateTime.UtcNow;
        await _postRepository.SaveChangesAsync();
    }

    public async Task<Guid> CreateGroupPostAsync(Guid groupId, CreatePostRequest request, string userId)
    {
        ValidateContent(request);
        var group = await GetActiveGroupAsync(groupId);
        if (!group.Members.Any(member => member.UserId == userId))
            throw new UnauthorizedAccessException("Only group members can post in this group");

        var post = BuildPost(request, userId, groupId);
        await _postRepository.AddAsync(post);
        await _postRepository.SaveChangesAsync();
        return post.Id;
    }

    public async Task<PagedResult<PostResponse>> GetGroupFeedAsync(Guid groupId, PostQuery query, string userId)
    {
        var group = await GetActiveGroupAsync(groupId);
        if (!group.Members.Any(member => member.UserId == userId))
            throw new UnauthorizedAccessException("Only group members can view this group's posts");
        return MapPage(await _postRepository.GetGroupFeedAsync(groupId, query));
    }

    public async Task DeleteGroupPostAsync(Guid groupId, Guid postId, string userId)
    {
        var group = await GetActiveGroupAsync(groupId);
        var post = await _postRepository.GetByIdAsync(postId);
        if (post == null || post.IsDeleted || post.GroupId != groupId)
            throw new KeyNotFoundException("Post not found");
        if (post.UserId != userId && group.OwnerId != userId)
            throw new UnauthorizedAccessException("Only the author or group owner can delete this post");
        post.IsDeleted = true;
        post.UpdatedDate = DateTime.UtcNow;
        await _postRepository.SaveChangesAsync();
    }

    private async Task<Post> GetOwnedPostAsync(Guid postId, string userId)
    {
        var post = await _postRepository.GetByIdAsync(postId);
        if (post == null || post.IsDeleted) throw new KeyNotFoundException("Post not found");
        if (post.UserId != userId) throw new UnauthorizedAccessException("Only the author can modify this post");
        return post;
    }

    private async Task<Group> GetActiveGroupAsync(Guid groupId)
    {
        var group = await _groupRepository.GetByIdAsync(groupId);
        if (group == null || group.IsDeleted) throw new KeyNotFoundException("Group not found");
        return group;
    }

    private static Post BuildPost(CreatePostRequest request, string userId, Guid? groupId) => new()
    {
        Id = Guid.NewGuid(),
        GroupId = groupId,
        UserId = userId,
        Content = request.Content.Trim(),
        MediaUrl = string.IsNullOrWhiteSpace(request.MediaUrl) ? null : request.MediaUrl.Trim(),
        MediaType = request.MediaType,
        CreatedDate = DateTime.UtcNow,
        IsDeleted = false
    };

    private void ValidateContent(CreatePostRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Content) && string.IsNullOrWhiteSpace(request.MediaUrl))
            throw new ArgumentException("Post must have content or media");
        if (request.Content.Length > 5000) throw new ArgumentException("Post content is too long");
        if (!_contentFilter.IsAllowed(request.Content))
            throw new ArgumentException("Post content violates community safety rules");
    }

    private static PagedResult<PostResponse> MapPage(PagedResult<Post> result) => new()
    {
        Items = result.Items.Select(Map).ToList(),
        Page = result.Page,
        PageSize = result.PageSize,
        Total = result.Total
    };

    private static PostResponse Map(Post post) => new()
    {
        Id = post.Id,
        GroupId = post.GroupId,
        GroupName = post.Group?.Name,
        UserId = post.UserId,
        AuthorName = post.User?.DisplayName ?? "Member",
        AuthorAvatarUrl = post.User?.AvatarUrl,
        Content = post.Content,
        MediaUrl = post.MediaUrl,
        MediaType = post.MediaType,
        CreatedDate = post.CreatedDate,
        UpdatedDate = post.UpdatedDate,
        CommentCount = post.Comments?.Count(comment => !comment.IsDeleted) ?? 0,
        ReactionCount = post.Reactions?.Count ?? 0,
        ReactionCounts = post.Reactions?.GroupBy(reaction => reaction.Type)
            .ToDictionary(group => group.Key, group => group.Count())
            ?? new Dictionary<int, int>()
    };
}
