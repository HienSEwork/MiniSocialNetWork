using MiniSocialNetwork.Application.DTOs.Friend;

namespace MiniSocialNetwork.Application.Interfaces;

public interface IFriendService
{
    Task<Guid> SendRequestAsync(string requesterId, string addresseeId);
    Task<IReadOnlyCollection<FriendRequestResponse>> GetIncomingRequestsAsync(string userId);
    Task RespondRequestAsync(Guid requestId, bool accept, string currentUserId);
    Task<IReadOnlyCollection<FriendUserResponse>> GetFriendsAsync(string userId);
    Task<IReadOnlyCollection<FriendUserResponse>> SearchUsersAsync(string userId, string? keyword);
    Task RemoveFriendAsync(string currentUserId, string friendId);
    Task<IReadOnlyCollection<RecommendationResponse>> RecommendAsync(string userId, int take = 20);
}
