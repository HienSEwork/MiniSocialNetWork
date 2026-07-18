using MiniSocialNetwork.Application.DTOs.Post;

namespace MiniSocialNetwork.Application.Interfaces;

public interface IPostService
{
    Task<Guid> CreateGroupPostAsync(Guid groupId, CreatePostRequest request, string userId);
    Task<PagedResult<PostResponse>> GetGroupFeedAsync(Guid groupId, PostQuery query);
    Task DeleteGroupPostAsync(Guid groupId, Guid postId, string userId);
}
