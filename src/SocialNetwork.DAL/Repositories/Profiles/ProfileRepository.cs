using Microsoft.EntityFrameworkCore;
using SocialNetwork.DAL.Entities;

namespace SocialNetwork.DAL.Repositories;

public class ProfileRepository(IDbContextFactory<ApplicationDbContext> dbContextFactory) : IProfileRepository
{
    public async Task<IReadOnlyList<ApplicationUser>> GetUsersAsync(string? excludeUserId = null)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        return await dbContext.Users
            .AsNoTracking()
            .Where(user => excludeUserId == null || user.Id != excludeUserId)
            .OrderBy(user => user.DisplayName)
            .ToListAsync();
    }

    public async Task<ApplicationUser?> GetUserAsync(string userId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        return await dbContext.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(user => user.Id == userId);
    }

    public async Task<int> CountPostsByUserAsync(string userId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        return await dbContext.Posts.CountAsync(post => post.UserId == userId);
    }

    public async Task<int> CountGroupMembershipsByUserAsync(string userId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        return await dbContext.GroupMembers.CountAsync(member => member.UserId == userId);
    }

    public async Task<bool> UpdateProfileAsync(string userId, string displayName, string? avatarUrl, string? bio)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        var user = await dbContext.Users.FirstOrDefaultAsync(item => item.Id == userId);
        if (user is null)
        {
            return false;
        }

        user.DisplayName = displayName;
        user.AvatarUrl = avatarUrl;
        user.Bio = bio;
        await dbContext.SaveChangesAsync();
        return true;
    }
}
