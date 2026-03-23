using SocialNetwork.BLL.Contracts;

namespace SocialNetwork.BLL.Interfaces;

public interface IFriendshipService
{
    Task<IReadOnlyList<FriendSummaryDto>> GetPeopleAsync(string currentUserId);

    Task<IReadOnlyList<UserSummaryDto>> GetFriendsAsync(string currentUserId);

    Task<bool> AreFriendsAsync(string firstUserId, string secondUserId);

    Task AddFriendAsync(string currentUserId, string otherUserId);

    Task RemoveFriendAsync(string currentUserId, string otherUserId);
}
