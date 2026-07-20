using MiniSocialNetwork.Application.DTOs.Post;
using MiniSocialNetwork.Application.DTOs.Search;
using MiniSocialNetwork.Application.Interfaces;
using MiniSocialNetwork.Application.Interfaces.Repositories;
using MiniSocialNetwork.Domain.Entities;

namespace MiniSocialNetwork.Application.Services;

public sealed class SearchService : ISearchService
{
    private readonly ISearchRepository _searchRepository;

    public SearchService(ISearchRepository searchRepository)
    {
        _searchRepository = searchRepository;
    }

    public async Task<SearchResponse> SearchAsync(string? query, int limit = 10)
    {
        var normalizedQuery = query?.Trim() ?? string.Empty;
        if (normalizedQuery.Length < 2)
            throw new ArgumentException("Search query must contain at least 2 characters");
        if (normalizedQuery.Length > 100)
            throw new ArgumentException("Search query cannot exceed 100 characters");

        var safeLimit = Math.Clamp(limit, 1, 20);
        var result = await _searchRepository.SearchAsync(normalizedQuery, safeLimit);

        return new SearchResponse
        {
            Query = normalizedQuery,
            UserTotal = result.UserTotal,
            GroupTotal = result.GroupTotal,
            PostTotal = result.PostTotal,
            Users = result.Users.Select(MapUser).ToList(),
            Groups = result.Groups.Select(MapGroup).ToList(),
            Posts = result.Posts.Select(MapPost).ToList()
        };
    }

    private static SearchUserResponse MapUser(AppUser user) => new()
    {
        Id = user.Id,
        DisplayName = user.DisplayName,
        AvatarUrl = user.AvatarUrl,
        Bio = user.Bio,
        CreatedDate = user.CreatedDate
    };

    private static SearchGroupResponse MapGroup(Group group) => new()
    {
        Id = group.Id,
        Name = group.Name,
        Description = group.Description,
        AvatarUrl = group.AvatarUrl,
        OwnerId = group.OwnerId,
        MemberCount = group.Members.Count,
        CreatedDate = group.CreatedDate
    };

    private static PostResponse MapPost(Post post) => new()
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
        CommentCount = post.Comments.Count(comment => !comment.IsDeleted),
        ReactionCount = post.Reactions.Count,
        ReactionCounts = post.Reactions
            .GroupBy(reaction => reaction.Type)
            .ToDictionary(group => group.Key, group => group.Count())
    };
}
