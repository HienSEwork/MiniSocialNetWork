using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
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
}
