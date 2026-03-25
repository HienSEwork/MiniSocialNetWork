using SocialNetwork.BLL.Contracts;
using SocialNetwork.BLL.Interfaces;
using SocialNetwork.DAL.Entities;
using SocialNetwork.DAL.Enums;
using SocialNetwork.DAL.Repositories;

namespace SocialNetwork.BLL.Services;

public class NotificationService(INotificationRepository notificationRepository, IFriendshipService friendshipService) : INotificationService
{
    public async Task<IReadOnlyList<NotificationDto>> GetNotificationsAsync(string userId)
    {
        var notifications = await notificationRepository.GetNotificationsForUserAsync(userId);
        return notifications.Select(MapNotification).ToList();
    }

    public Task MarkAllAsReadAsync(string userId) =>
        notificationRepository.MarkAllAsReadAsync(userId);

    public async Task<IReadOnlyList<NotificationDto>> CreateFriendNotificationsForPostAsync(string actorId, Guid postId, string message)
    {
        var friends = await friendshipService.GetFriendsAsync(actorId);
        var notifications = friends
            .Select(friend => new Notification
            {
                UserId = friend.Id,
                ActorId = actorId,
                Type = NotificationType.NewPost,
                Title = "Bài đăng mới",
                Message = message,
                Link = $"/posts/{postId}"
            })
            .ToList();

        if (notifications.Count == 0)
        {
            return [];
        }

        await notificationRepository.AddNotificationsAsync(notifications);
        await notificationRepository.LoadActorsAsync(notifications);
        return notifications.Select(MapNotification).ToList();
    }

    public async Task<IReadOnlyList<NotificationDto>> CreateInteractionNotificationAsync(string actorId, string recipientId, NotificationType type, string title, string message, string? link = null)
    {
        var areFriends = await friendshipService.AreFriendsAsync(actorId, recipientId);
        if (actorId == recipientId || (type != NotificationType.FriendAdded && !areFriends))
        {
            return [];
        }

        var notification = new Notification
        {
            UserId = recipientId,
            ActorId = actorId,
            Type = type,
            Title = title,
            Message = message,
            Link = link
        };

        await notificationRepository.AddNotificationAsync(notification);
        await notificationRepository.LoadActorsAsync([notification]);
        return [MapNotification(notification)];
    }

    public Task<IReadOnlyList<NotificationDto>> CreatePrivateMessageNotificationAsync(string senderId, string receiverId, string message) =>
        CreateInteractionNotificationAsync(
            senderId,
            receiverId,
            NotificationType.NewMessage,
            "Tin nhắn mới",
            message,
            "/chat");

    private static NotificationDto MapNotification(Notification notification) =>
        new(
            notification.Id,
            notification.UserId,
            notification.ActorId,
            string.IsNullOrWhiteSpace(notification.Actor.DisplayName) ? notification.Actor.Email ?? notification.Actor.UserName ?? "Người dùng" : notification.Actor.DisplayName,
            notification.Type,
            notification.Title,
            notification.Message,
            notification.Link,
            notification.IsRead,
            notification.CreatedDate);
}
