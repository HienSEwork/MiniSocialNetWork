using Microsoft.EntityFrameworkCore;
using SocialNetwork.BLL.Contracts;
using SocialNetwork.BLL.Interfaces;
using SocialNetwork.DAL;
using SocialNetwork.DAL.Entities;
using SocialNetwork.DAL.Enums;

namespace SocialNetwork.BLL.Services;

public class NotificationService(IDbContextFactory<ApplicationDbContext> dbContextFactory, IFriendshipService friendshipService) : INotificationService
{
    public async Task<IReadOnlyList<NotificationDto>> GetNotificationsAsync(string userId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        var notifications = await dbContext.Notifications
            .AsNoTracking()
            .Include(item => item.Actor)
            .Where(item => item.UserId == userId)
            .OrderByDescending(item => item.CreatedDate)
            .Take(50)
            .ToListAsync();

        return notifications.Select(MapNotification).ToList();
    }

    public async Task MarkAllAsReadAsync(string userId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        var notifications = await dbContext.Notifications.Where(item => item.UserId == userId && !item.IsRead).ToListAsync();
        foreach (var notification in notifications)
        {
            notification.IsRead = true;
        }

        await dbContext.SaveChangesAsync();
    }

    public async Task<IReadOnlyList<NotificationDto>> CreateFriendNotificationsForPostAsync(string actorId, Guid postId, string message)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        var friends = await friendshipService.GetFriendsAsync(actorId);
        var notifications = new List<Notification>();

        foreach (var friend in friends)
        {
            notifications.Add(new Notification
            {
                UserId = friend.Id,
                ActorId = actorId,
                Type = NotificationType.NewPost,
                Title = "Bài đăng mới",
                Message = message,
                Link = $"/posts/{postId}"
            });
        }

        if (notifications.Count == 0)
        {
            return Array.Empty<NotificationDto>();
        }

        dbContext.Notifications.AddRange(notifications);
        await dbContext.SaveChangesAsync();
        await LoadActorsAsync(dbContext, notifications);
        return notifications.Select(MapNotification).ToList();
    }

    public async Task<IReadOnlyList<NotificationDto>> CreateInteractionNotificationAsync(string actorId, string recipientId, NotificationType type, string title, string message, string? link = null)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        var areFriends = await friendshipService.AreFriendsAsync(actorId, recipientId);
        if (actorId == recipientId || (type != NotificationType.FriendAdded && !areFriends))
        {
            return Array.Empty<NotificationDto>();
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

        dbContext.Notifications.Add(notification);
        await dbContext.SaveChangesAsync();
        await LoadActorsAsync(dbContext, [notification]);
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

    private static async Task LoadActorsAsync(ApplicationDbContext dbContext, IEnumerable<Notification> notifications)
    {
        var actorIds = notifications.Select(item => item.ActorId).Distinct().ToList();
        var actors = await dbContext.Users.Where(user => actorIds.Contains(user.Id)).ToDictionaryAsync(user => user.Id);

        foreach (var notification in notifications)
        {
            notification.Actor = actors[notification.ActorId];
        }
    }

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
