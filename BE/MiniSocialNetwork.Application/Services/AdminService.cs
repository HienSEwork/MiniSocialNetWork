using MiniSocialNetwork.Application.DTOs.Admin;
using MiniSocialNetwork.Application.Interfaces;
using MiniSocialNetwork.Application.Interfaces.Repositories;
using MiniSocialNetwork.Domain.Entities;

namespace MiniSocialNetwork.Application.Services;

public class AdminService : IAdminService
{
    private readonly IAdminRepository _repo;

    public AdminService(IAdminRepository repo)
    {
        _repo = repo;
    }

    public Task<DashboardStatsResponse> GetStatsAsync()
        => _repo.GetStatsAsync();

    public Task<List<PostsPerDayItem>> GetPostsPerDayAsync(int days)
        => _repo.GetPostsPerDayAsync(days);

    public async Task<PagedResult<UserResponse>> GetUsersAsync(UserQuery query)
    {
        var result = await _repo.GetUsersAsync(query);

        return new PagedResult<UserResponse>
        {
            Items = result.Items.Select(MapToResponse).ToList(),
            Page = result.Page,
            PageSize = result.PageSize,
            Total = result.Total
        };
    }

    public async Task DeleteUserAsync(string userId)
    {
        var user = await _repo.GetUserByIdAsync(userId);
        if (user == null || user.IsDeleted)
            throw new KeyNotFoundException("User not found");

        user.IsDeleted = true;

        await _repo.SaveChangesAsync();
    }

    private static UserResponse MapToResponse(AppUser u) => new()
    {
        Id = u.Id,
        UserName = u.UserName,
        Email = u.Email,
        DisplayName = u.DisplayName,
        AvatarUrl = u.AvatarUrl,
        CreatedDate = u.CreatedDate
    };
}
