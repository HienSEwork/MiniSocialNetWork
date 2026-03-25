using SocialNetwork.BLL.Contracts;
using SocialNetwork.BLL.Interfaces;
using SocialNetwork.DAL.Entities;
using SocialNetwork.DAL.Enums;
using SocialNetwork.DAL.Repositories;

namespace SocialNetwork.BLL.Services;

public class FriendshipService(IFriendshipRepository friendshipRepository) : IFriendshipService
{
    public async Task<IReadOnlyList<FriendSummaryDto>> GetPeopleAsync(string currentUserId)
    {
        var friendships = await friendshipRepository.GetFriendshipsForUserAsync(currentUserId);
        var friendshipLookup = friendships
            .GroupBy(item => item.RequesterId == currentUserId ? item.AddresseeId : item.RequesterId)
            .ToDictionary(
                group => group.Key,
                group => group
                    .OrderByDescending(item => item.Status == FriendshipStatus.Accepted)
                    .ThenByDescending(item => item.CreatedDate)
                    .First());

        var users = await friendshipRepository.GetUsersExceptAsync(currentUserId);

        return users
            .Select(user =>
            {
                friendshipLookup.TryGetValue(user.Id, out var friendship);

                var isFriend = friendship?.Status == FriendshipStatus.Accepted;
                var hasSentRequest = friendship is not null
                    && friendship.Status == FriendshipStatus.Pending
                    && friendship.RequesterId == currentUserId;
                var hasReceivedRequest = friendship is not null
                    && friendship.Status == FriendshipStatus.Pending
                    && friendship.AddresseeId == currentUserId;

                return new FriendSummaryDto(
                    user.Id,
                    string.IsNullOrWhiteSpace(user.DisplayName) ? user.Email ?? user.UserName ?? "Người dùng" : user.DisplayName,
                    user.Email ?? string.Empty,
                    user.AvatarUrl,
                    user.Bio,
                    isFriend,
                    hasSentRequest,
                    hasReceivedRequest);
            })
            .ToList();
    }

    public async Task<IReadOnlyList<UserSummaryDto>> GetFriendsAsync(string currentUserId)
    {
        var friendships = await friendshipRepository.GetFriendshipsForUserAsync(currentUserId);
        var friendIds = friendships
            .Where(item => item.Status == FriendshipStatus.Accepted)
            .Select(item => item.RequesterId == currentUserId ? item.AddresseeId : item.RequesterId)
            .Distinct()
            .ToList();

        var users = await friendshipRepository.GetUsersByIdsAsync(friendIds);

        return users
            .Select(user => new UserSummaryDto(
                user.Id,
                string.IsNullOrWhiteSpace(user.DisplayName) ? user.Email ?? user.UserName ?? "Người dùng" : user.DisplayName,
                user.Email ?? string.Empty,
                user.AvatarUrl,
                user.Bio))
            .ToList();
    }

    public Task<bool> AreFriendsAsync(string firstUserId, string secondUserId) =>
        friendshipRepository.AreFriendsAsync(firstUserId, secondUserId);

    public async Task AddFriendAsync(string currentUserId, string otherUserId)
    {
        if (currentUserId == otherUserId)
        {
            throw new InvalidOperationException("Bạn không thể tự kết bạn với chính mình.");
        }

        var friendship = await friendshipRepository.FindFriendshipAsync(currentUserId, otherUserId);
        if (friendship is not null)
        {
            if (friendship.Status == FriendshipStatus.Accepted)
            {
                return;
            }

            if (friendship.RequesterId == currentUserId && friendship.AddresseeId == otherUserId)
            {
                return;
            }

            await friendshipRepository.UpdateStatusAsync(friendship.Id, FriendshipStatus.Accepted);
            return;
        }

        await friendshipRepository.AddFriendshipAsync(new Friendship
        {
            RequesterId = currentUserId,
            AddresseeId = otherUserId,
            Status = FriendshipStatus.Pending
        });
    }

    public async Task AcceptFriendRequestAsync(string currentUserId, string otherUserId)
    {
        var friendship = await friendshipRepository.FindFriendshipAsync(currentUserId, otherUserId);
        if (friendship is null ||
            friendship.RequesterId != otherUserId ||
            friendship.AddresseeId != currentUserId ||
            friendship.Status != FriendshipStatus.Pending)
        {
            return;
        }

        await friendshipRepository.UpdateStatusAsync(friendship.Id, FriendshipStatus.Accepted);
    }

    public async Task RejectFriendRequestAsync(string currentUserId, string otherUserId)
    {
        var friendship = await friendshipRepository.FindFriendshipAsync(currentUserId, otherUserId);
        if (friendship is null ||
            friendship.RequesterId != otherUserId ||
            friendship.AddresseeId != currentUserId ||
            friendship.Status != FriendshipStatus.Pending)
        {
            return;
        }

        await friendshipRepository.RemoveFriendshipAsync(friendship.Id);
    }

    public async Task RemoveFriendAsync(string currentUserId, string otherUserId)
    {
        var friendship = await friendshipRepository.FindFriendshipAsync(currentUserId, otherUserId);
        if (friendship is null)
        {
            return;
        }

        await friendshipRepository.RemoveFriendshipAsync(friendship.Id);
    }
}
