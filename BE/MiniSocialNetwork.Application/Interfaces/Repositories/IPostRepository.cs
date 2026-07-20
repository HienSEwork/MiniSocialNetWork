using MiniSocialNetwork.Application.DTOs.Post;
using MiniSocialNetwork.Domain.Entities;

namespace MiniSocialNetwork.Application.Interfaces.Repositories;

public interface IPostRepository
{
    Task<PagedResult<Post>> GetFeedAsync(PostQuery query, string userId);
    Task<PagedResult<Post>> GetGroupFeedAsync(Guid groupId, PostQuery query);
    Task<Post?> GetByIdAsync(Guid id);
    Task AddAsync(Post post);
    Task SaveChangesAsync();
}
