using MiniSocialNetwork.Application.DTOs.Post;
using MiniSocialNetwork.Application.Interfaces;
using MiniSocialNetwork.Application.Interfaces.Repositories;
using MiniSocialNetwork.Domain.Entities;

namespace MiniSocialNetwork.Application.Services;

public class PostService : IPostService
{
    private readonly IPostRepository _postRepo;
    private readonly IGroupRepository _groupRepo;

    public PostService(IPostRepository postRepo, IGroupRepository groupRepo)
    {
        _postRepo = postRepo;
        _groupRepo = groupRepo;
    }

    public async Task<Guid> CreateGroupPostAsync(Guid groupId, CreatePostRequest req, string userId)
    {
        if (string.IsNullOrWhiteSpace(req.Content) && string.IsNullOrWhiteSpace(req.MediaUrl))
            throw new ArgumentException("Post must have content or media");

        var group = await GetActiveGroupAsync(groupId);

        if (!group.Members.Any(m => m.UserId == userId))
            throw new UnauthorizedAccessException("Only group members can post in this group");

        var post = new Post
        {
            Id = Guid.NewGuid(),
            GroupId = groupId,
            UserId = userId,
            Content = req.Content?.Trim() ?? string.Empty,
            MediaUrl = req.MediaUrl,
            MediaType = req.MediaType,
            CreatedDate = DateTime.UtcNow,
            IsDeleted = false
        };

        await _postRepo.AddAsync(post);
        await _postRepo.SaveChangesAsync();

        return post.Id;
    }

    public async Task<PagedResult<PostResponse>> GetGroupFeedAsync(Guid groupId, PostQuery query)
    {
        await GetActiveGroupAsync(groupId);

        var result = await _postRepo.GetGroupFeedAsync(groupId, query);

        return new PagedResult<PostResponse>
        {
            Items = result.Items.Select(MapToResponse).ToList(),
            Page = result.Page,
            PageSize = result.PageSize,
            Total = result.Total
        };
    }

    public async Task DeleteGroupPostAsync(Guid groupId, Guid postId, string userId)
    {
        var group = await GetActiveGroupAsync(groupId);

        var post = await _postRepo.GetByIdAsync(postId);
        if (post == null || post.IsDeleted || post.GroupId != groupId)
            throw new KeyNotFoundException("Post not found");

        var isAuthor = post.UserId == userId;
        var isOwner = group.OwnerId == userId;
        if (!isAuthor && !isOwner)
            throw new UnauthorizedAccessException("Only the author or the group owner can delete this post");

        post.IsDeleted = true;
        post.UpdatedDate = DateTime.UtcNow;

        await _postRepo.SaveChangesAsync();
    }

    private async Task<Group> GetActiveGroupAsync(Guid groupId)
    {
        var group = await _groupRepo.GetByIdAsync(groupId);
        if (group == null || group.IsDeleted)
            throw new KeyNotFoundException("Group not found");

        return group;
    }

    private static PostResponse MapToResponse(Post p) => new()
    {
        Id = p.Id,
        GroupId = p.GroupId,
        UserId = p.UserId,
        Content = p.Content,
        MediaUrl = p.MediaUrl,
        MediaType = p.MediaType,
        CreatedDate = p.CreatedDate,
        UpdatedDate = p.UpdatedDate,
        CommentCount = p.Comments?.Count(c => !c.IsDeleted) ?? 0,
        ReactionCount = p.Reactions?.Count ?? 0
    };
}
