using MiniSocialNetwork.Application.DTOs.Post;

namespace MiniSocialNetwork.Application.Interfaces;

public interface IPostService
{
    Task<Guid> CreateAsync(CreatePostRequest request, string userId);
    Task<PagedResult<PostResponse>> GetFeedAsync(PostQuery query, string userId);
    Task<PostResponse> GetByIdAsync(Guid postId);
    Task UpdateAsync(Guid postId, CreatePostRequest request, string userId);
    Task DeleteAsync(Guid postId, string userId);
    Task<Guid> CreateGroupPostAsync(Guid groupId, CreatePostRequest request, string userId);
    Task<PagedResult<PostResponse>> GetGroupFeedAsync(Guid groupId, PostQuery query, string userId);
    Task DeleteGroupPostAsync(Guid groupId, Guid postId, string userId);
}
