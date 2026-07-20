using MiniSocialNetwork.Application.DTOs.Admin;

namespace MiniSocialNetwork.Application.Interfaces;

public interface IAdminService
{
    Task<DashboardStatsResponse> GetStatsAsync();
    Task<List<PostsPerDayItem>> GetPostsPerDayAsync(int days);
    Task<PagedResult<UserResponse>> GetUsersAsync(UserQuery query);
    Task DeleteUserAsync(string userId);
}
