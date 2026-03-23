using SocialNetwork.BLL.Contracts;

namespace SocialNetwork.BLL.Interfaces;

public interface IChatService
{
    Task<IReadOnlyList<UserSummaryDto>> GetChatUsersAsync(string currentUserId);

    Task<IReadOnlyList<MessageDto>> GetPrivateConversationAsync(string currentUserId, string otherUserId);

    Task<IReadOnlyList<MessageDto>> GetGroupConversationAsync(string currentUserId, Guid groupId);

    Task<MessageDto> SavePrivateMessageAsync(string senderId, string receiverId, string content);

    Task<MessageDto> SaveGroupMessageAsync(string senderId, Guid groupId, string content);
}
