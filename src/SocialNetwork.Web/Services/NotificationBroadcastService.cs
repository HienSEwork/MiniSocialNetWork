using Microsoft.AspNetCore.SignalR;
using SocialNetwork.BLL.Contracts;
using SocialNetwork.Web.Hubs;

namespace SocialNetwork.Web.Services;

public class NotificationBroadcastService(IHubContext<NotificationHub> hubContext)
{
    public Task BroadcastSocialUpdatedAsync() =>
        hubContext.Clients.All.SendAsync("SocialUpdated");

    public Task BroadcastNotificationsAsync(IEnumerable<NotificationDto> notifications) =>
        Task.WhenAll(notifications.Select(notification =>
            hubContext.Clients.Group(notification.UserId).SendAsync("NotificationReceived", notification)));
}
