using Microsoft.AspNetCore.SignalR;

namespace MiniSocialNetwork.API.Hubs;

public class NotificationHub : Hub
{
    // Broadcast a simple notification message to all connected clients
    public Task BroadcastNotification(string title, string message)
        => Clients.All.SendAsync("ReceiveNotification", title, message);

    public override Task OnConnectedAsync()
    {
        return base.OnConnectedAsync();
    }

    public override Task OnDisconnectedAsync(Exception? exception)
    {
        return base.OnDisconnectedAsync(exception);
    }
}
