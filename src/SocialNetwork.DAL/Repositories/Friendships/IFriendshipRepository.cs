using SocialNetwork.DAL.Entities;
using SocialNetwork.DAL.Enums;

namespace SocialNetwork.DAL.Repositories;

public interface IFriendshipRepository
{
    Task<IReadOnlyList<Friendship>> GetFriendshipsForUserAsync(string userId);

    Task<IReadOnlyList<ApplicationUser>> GetUsersExceptAsync(string userId);

    Task<IReadOnlyList<ApplicationUser>> GetUsersByIdsAsync(IReadOnlyCollection<string> userIds);

    Task<bool> AreFriendsAsync(string firstUserId, string secondUserId);

    Task<Friendship?> FindFriendshipAsync(string firstUserId, string secondUserId);

    Task AddFriendshipAsync(Friendship friendship);

    Task<bool> UpdateStatusAsync(Guid friendshipId, FriendshipStatus status);

    Task<bool> RemoveFriendshipAsync(Guid friendshipId);
}
