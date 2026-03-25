using Microsoft.EntityFrameworkCore;
using SocialNetwork.DAL.Entities;

namespace SocialNetwork.DAL.Repositories;

public class NotificationRepository(IDbContextFactory<ApplicationDbContext> dbContextFactory) : INotificationRepository
{
    public async Task<IReadOnlyList<Notification>> GetNotificationsForUserAsync(string userId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        return await dbContext.Notifications
            .AsNoTracking()
            .Include(notification => notification.Actor)
            .Where(notification => notification.UserId == userId)
            .OrderByDescending(notification => notification.CreatedDate)
            .Take(50)
            .ToListAsync();
    }

    public async Task MarkAllAsReadAsync(string userId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        var notifications = await dbContext.Notifications
            .Where(notification => notification.UserId == userId && !notification.IsRead)
            .ToListAsync();

        foreach (var notification in notifications)
        {
            notification.IsRead = true;
        }

        await dbContext.SaveChangesAsync();
    }

    public async Task AddNotificationAsync(Notification notification)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        dbContext.Notifications.Add(notification);
        await dbContext.SaveChangesAsync();
    }

    public async Task AddNotificationsAsync(IEnumerable<Notification> notifications)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        dbContext.Notifications.AddRange(notifications);
        await dbContext.SaveChangesAsync();
    }

    public async Task LoadActorsAsync(IEnumerable<Notification> notifications)
    {
        var actorIds = notifications.Select(notification => notification.ActorId).Distinct().ToList();
        if (actorIds.Count == 0)
        {
            return;
        }

        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        var actors = await dbContext.Users
            .Where(user => actorIds.Contains(user.Id))
            .ToDictionaryAsync(user => user.Id);

        foreach (var notification in notifications)
        {
            notification.Actor = actors[notification.ActorId];
        }
    }
}
