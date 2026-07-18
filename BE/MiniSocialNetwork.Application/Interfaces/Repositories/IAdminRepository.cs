using MiniSocialNetwork.Application.DTOs.Admin;
using MiniSocialNetwork.Domain.Entities;

namespace MiniSocialNetwork.Application.Interfaces.Repositories;

public interface IAdminRepository
{
    Task<DashboardStatsResponse> GetStatsAsync();
    Task<List<PostsPerDayItem>> GetPostsPerDayAsync(int days);
    Task<PagedResult<AppUser>> GetUsersAsync(UserQuery query);
    Task<AppUser?> GetUserByIdAsync(string id);
    Task SaveChangesAsync();
}
