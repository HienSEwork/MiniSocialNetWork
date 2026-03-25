using SocialNetwork.BLL.Contracts;
using SocialNetwork.BLL.Interfaces;
using SocialNetwork.DAL.Entities;
using SocialNetwork.DAL.Repositories;

namespace SocialNetwork.BLL.Services;

public class ChatService(IChatRepository chatRepository, IFriendshipService friendshipService) : IChatService
{
    public async Task<IReadOnlyList<UserSummaryDto>> GetChatUsersAsync(string currentUserId)
    {
        return await friendshipService.GetFriendsAsync(currentUserId);
    }

    public async Task<IReadOnlyList<MessageDto>> GetPrivateConversationAsync(string currentUserId, string otherUserId)
    {
        if (!await friendshipService.AreFriendsAsync(currentUserId, otherUserId))
        {
            throw new InvalidOperationException("Chỉ có thể nhắn tin riêng với người đã kết bạn.");
        }

        var messages = await chatRepository.GetPrivateConversationAsync(currentUserId, otherUserId);
        return messages.Select(message => MapMessage(message, currentUserId)).ToList();
    }

    public async Task<IReadOnlyList<MessageDto>> GetGroupConversationAsync(string currentUserId, Guid groupId)
    {
        if (!await chatRepository.IsUserMemberOfGroupAsync(currentUserId, groupId))
        {
            throw new InvalidOperationException("Bạn phải tham gia nhóm trước khi mở chat nhóm.");
        }

        var messages = await chatRepository.GetGroupConversationAsync(groupId);
        return messages.Select(message => MapMessage(message, currentUserId)).ToList();
    }

    public async Task<MessageDto> SavePrivateMessageAsync(string senderId, string receiverId, string content)
    {
        if (string.IsNullOrWhiteSpace(content))
        {
            throw new InvalidOperationException("Nội dung tin nhắn là bắt buộc.");
        }

        if (!await friendshipService.AreFriendsAsync(senderId, receiverId))
        {
            throw new InvalidOperationException("Chỉ có thể nhắn tin riêng với người đã kết bạn.");
        }

        var message = new Message
        {
            SenderId = senderId,
            ReceiverId = receiverId,
            Content = content.Trim(),
            IsGroupMessage = false
        };

        await chatRepository.AddMessageAsync(message);

        var sender = await chatRepository.GetRequiredUserAsync(senderId);
        message.Sender = sender;
        return MapMessage(message, senderId);
    }

    public async Task<MessageDto> SaveGroupMessageAsync(string senderId, Guid groupId, string content)
    {
        if (string.IsNullOrWhiteSpace(content))
        {
            throw new InvalidOperationException("Nội dung tin nhắn là bắt buộc.");
        }

        if (!await chatRepository.IsUserMemberOfGroupAsync(senderId, groupId))
        {
            throw new InvalidOperationException("Bạn phải tham gia nhóm trước khi gửi tin nhắn.");
        }

        var message = new Message
        {
            SenderId = senderId,
            GroupId = groupId,
            Content = content.Trim(),
            IsGroupMessage = true
        };

        await chatRepository.AddMessageAsync(message);

        var sender = await chatRepository.GetRequiredUserAsync(senderId);
        message.Sender = sender;
        return MapMessage(message, senderId);
    }

    private static MessageDto MapMessage(Message message, string currentUserId) =>
        new(
            message.Id,
            message.SenderId,
            string.IsNullOrWhiteSpace(message.Sender.DisplayName) ? message.Sender.Email ?? message.Sender.UserName ?? "Người dùng" : message.Sender.DisplayName,
            message.Sender.AvatarUrl,
            message.ReceiverId,
            message.GroupId,
            message.Content,
            message.CreatedDate,
            message.SenderId == currentUserId,
            message.IsGroupMessage);
}
