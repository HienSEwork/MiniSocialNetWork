using Microsoft.EntityFrameworkCore;
using SocialNetwork.BLL.Contracts;
using SocialNetwork.BLL.Interfaces;
using SocialNetwork.DAL;
using SocialNetwork.DAL.Entities;

namespace SocialNetwork.BLL.Services;

public class FriendshipService(IDbContextFactory<ApplicationDbContext> dbContextFactory) : IFriendshipService
{
    public async Task<IReadOnlyList<FriendSummaryDto>> GetPeopleAsync(string currentUserId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        var friendshipPairs = await dbContext.Friendships
            .AsNoTracking()
            .Where(item => item.RequesterId == currentUserId || item.AddresseeId == currentUserId)
            .Select(item => item.RequesterId == currentUserId ? item.AddresseeId : item.RequesterId)
            .ToListAsync();

        return await dbContext.Users
            .AsNoTracking()
            .Where(user => user.Id != currentUserId)
            .OrderBy(user => user.DisplayName)
            .Select(user => new FriendSummaryDto(
                user.Id,
                string.IsNullOrWhiteSpace(user.DisplayName) ? user.Email ?? user.UserName ?? "Người dùng" : user.DisplayName,
                user.Email ?? string.Empty,
                user.AvatarUrl,
                user.Bio,
                friendshipPairs.Contains(user.Id)))
            .ToListAsync();
    }

    public async Task<IReadOnlyList<UserSummaryDto>> GetFriendsAsync(string currentUserId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        var friendIds = await dbContext.Friendships
            .AsNoTracking()
            .Where(item => item.RequesterId == currentUserId || item.AddresseeId == currentUserId)
            .Select(item => item.RequesterId == currentUserId ? item.AddresseeId : item.RequesterId)
            .ToListAsync();

        return await dbContext.Users
            .AsNoTracking()
            .Where(user => friendIds.Contains(user.Id))
            .OrderBy(user => user.DisplayName)
            .Select(user => new UserSummaryDto(
                user.Id,
                string.IsNullOrWhiteSpace(user.DisplayName) ? user.Email ?? user.UserName ?? "Người dùng" : user.DisplayName,
                user.Email ?? string.Empty,
                user.AvatarUrl,
                user.Bio))
            .ToListAsync();
    }

    public async Task<bool> AreFriendsAsync(string firstUserId, string secondUserId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        return await dbContext.Friendships.AnyAsync(item =>
            (item.RequesterId == firstUserId && item.AddresseeId == secondUserId) ||
            (item.RequesterId == secondUserId && item.AddresseeId == firstUserId));
    }

    public async Task AddFriendAsync(string currentUserId, string otherUserId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        if (currentUserId == otherUserId)
        {
            throw new InvalidOperationException("Bạn không thể tự kết bạn với chính mình.");
        }

        if (await AreFriendsAsync(currentUserId, otherUserId))
        {
            return;
        }

        var requesterId = string.CompareOrdinal(currentUserId, otherUserId) < 0 ? currentUserId : otherUserId;
        var addresseeId = requesterId == currentUserId ? otherUserId : currentUserId;

        dbContext.Friendships.Add(new Friendship
        {
            RequesterId = requesterId,
            AddresseeId = addresseeId
        });

        await dbContext.SaveChangesAsync();
    }

    public async Task RemoveFriendAsync(string currentUserId, string otherUserId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        var friendship = await dbContext.Friendships.FirstOrDefaultAsync(item =>
            (item.RequesterId == currentUserId && item.AddresseeId == otherUserId) ||
            (item.RequesterId == otherUserId && item.AddresseeId == currentUserId));

        if (friendship is null)
        {
            return;
        }

        dbContext.Friendships.Remove(friendship);
        await dbContext.SaveChangesAsync();
    }
}
