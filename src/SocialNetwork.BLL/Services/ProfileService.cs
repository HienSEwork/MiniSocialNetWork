using Microsoft.EntityFrameworkCore;
using SocialNetwork.BLL.Contracts;
using SocialNetwork.BLL.Interfaces;
using SocialNetwork.DAL;

namespace SocialNetwork.BLL.Services;

public class ProfileService(IDbContextFactory<ApplicationDbContext> dbContextFactory) : IProfileService
{
    public async Task<IReadOnlyList<UserSummaryDto>> GetUsersAsync(string? excludeUserId = null)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        return await dbContext.Users
            .AsNoTracking()
            .Where(user => excludeUserId == null || user.Id != excludeUserId)
            .OrderBy(user => user.DisplayName)
            .Select(user => new UserSummaryDto(
                user.Id,
                string.IsNullOrWhiteSpace(user.DisplayName) ? user.Email ?? user.UserName ?? "Người dùng" : user.DisplayName,
                user.Email ?? string.Empty,
                user.AvatarUrl,
                user.Bio))
            .ToListAsync();
    }

    public async Task<ProfileDto?> GetProfileAsync(string userId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        var user = await dbContext.Users.AsNoTracking().FirstOrDefaultAsync(item => item.Id == userId);
        if (user is null)
        {
            return null;
        }

        var postCount = await dbContext.Posts.CountAsync(post => post.UserId == userId);
        var groupCount = await dbContext.GroupMembers.CountAsync(member => member.UserId == userId);

        return new ProfileDto(
            user.Id,
            string.IsNullOrWhiteSpace(user.DisplayName) ? user.Email ?? user.UserName ?? "Người dùng" : user.DisplayName,
            user.Email ?? string.Empty,
            user.AvatarUrl,
            user.Bio,
            user.CreatedDate,
            postCount,
            groupCount);
    }

    public async Task UpdateProfileAsync(string userId, UpdateProfileRequest request)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        if (string.IsNullOrWhiteSpace(request.DisplayName))
        {
            throw new InvalidOperationException("Tên hiển thị là bắt buộc.");
        }

        var user = await dbContext.Users.FirstOrDefaultAsync(item => item.Id == userId)
            ?? throw new InvalidOperationException("Không tìm thấy người dùng.");

        user.DisplayName = request.DisplayName.Trim();
        user.AvatarUrl = string.IsNullOrWhiteSpace(request.AvatarUrl) ? null : request.AvatarUrl.Trim();
        user.Bio = string.IsNullOrWhiteSpace(request.Bio) ? null : request.Bio.Trim();
        await dbContext.SaveChangesAsync();
    }
}
