using SocialNetwork.BLL.Contracts;
using SocialNetwork.DAL.Enums;

namespace SocialNetwork.BLL.Interfaces;

public interface INotificationService
{
    Task<IReadOnlyList<NotificationDto>> GetNotificationsAsync(string userId);

    Task MarkAllAsReadAsync(string userId);

    Task<IReadOnlyList<NotificationDto>> CreateFriendNotificationsForPostAsync(string actorId, Guid postId, string message);

    Task<IReadOnlyList<NotificationDto>> CreateInteractionNotificationAsync(string actorId, string recipientId, NotificationType type, string title, string message, string? link = null);

    Task<IReadOnlyList<NotificationDto>> CreatePrivateMessageNotificationAsync(string senderId, string receiverId, string message);
}
