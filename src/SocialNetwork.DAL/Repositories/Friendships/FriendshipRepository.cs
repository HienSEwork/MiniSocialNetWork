using Microsoft.EntityFrameworkCore;
using SocialNetwork.DAL.Entities;
using SocialNetwork.DAL.Enums;

namespace SocialNetwork.DAL.Repositories;

public class FriendshipRepository(IDbContextFactory<ApplicationDbContext> dbContextFactory) : IFriendshipRepository
{
    public async Task<IReadOnlyList<Friendship>> GetFriendshipsForUserAsync(string userId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        return await dbContext.Friendships
            .AsNoTracking()
            .Where(friendship => friendship.RequesterId == userId || friendship.AddresseeId == userId)
            .ToListAsync();
    }

    public async Task<IReadOnlyList<ApplicationUser>> GetUsersExceptAsync(string userId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        return await dbContext.Users
            .AsNoTracking()
            .Where(user => user.Id != userId)
            .OrderBy(user => user.DisplayName)
            .ToListAsync();
    }

    public async Task<IReadOnlyList<ApplicationUser>> GetUsersByIdsAsync(IReadOnlyCollection<string> userIds)
    {
        if (userIds.Count == 0)
        {
            return [];
        }

        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        return await dbContext.Users
            .AsNoTracking()
            .Where(user => userIds.Contains(user.Id))
            .OrderBy(user => user.DisplayName)
            .ToListAsync();
    }

    public async Task<bool> AreFriendsAsync(string firstUserId, string secondUserId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        return await dbContext.Friendships.AnyAsync(friendship =>
            friendship.Status == FriendshipStatus.Accepted &&
            ((friendship.RequesterId == firstUserId && friendship.AddresseeId == secondUserId) ||
             (friendship.RequesterId == secondUserId && friendship.AddresseeId == firstUserId)));
    }

    public async Task<Friendship?> FindFriendshipAsync(string firstUserId, string secondUserId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        return await dbContext.Friendships
            .AsNoTracking()
            .FirstOrDefaultAsync(friendship =>
                (friendship.RequesterId == firstUserId && friendship.AddresseeId == secondUserId) ||
                (friendship.RequesterId == secondUserId && friendship.AddresseeId == firstUserId));
    }

    public async Task AddFriendshipAsync(Friendship friendship)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        dbContext.Friendships.Add(friendship);
        await dbContext.SaveChangesAsync();
    }

    public async Task<bool> UpdateStatusAsync(Guid friendshipId, FriendshipStatus status)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        var friendship = await dbContext.Friendships.FirstOrDefaultAsync(item => item.Id == friendshipId);
        if (friendship is null)
        {
            return false;
        }

        friendship.Status = status;
        await dbContext.SaveChangesAsync();
        return true;
    }

    public async Task<bool> RemoveFriendshipAsync(Guid friendshipId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        var friendship = await dbContext.Friendships.FirstOrDefaultAsync(item => item.Id == friendshipId);
        if (friendship is null)
        {
            return false;
        }

        dbContext.Friendships.Remove(friendship);
        await dbContext.SaveChangesAsync();
        return true;
    }
}
