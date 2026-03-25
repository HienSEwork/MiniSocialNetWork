using SocialNetwork.DAL.Entities;

namespace SocialNetwork.DAL.Repositories;

public interface INotificationRepository
{
    Task<IReadOnlyList<Notification>> GetNotificationsForUserAsync(string userId);

    Task MarkAllAsReadAsync(string userId);

    Task AddNotificationAsync(Notification notification);

    Task AddNotificationsAsync(IEnumerable<Notification> notifications);

    Task LoadActorsAsync(IEnumerable<Notification> notifications);
}
