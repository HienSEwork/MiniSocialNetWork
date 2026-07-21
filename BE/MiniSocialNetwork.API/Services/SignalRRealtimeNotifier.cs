using Microsoft.AspNetCore.SignalR;
using MiniSocialNetwork.API.Hubs;
using MiniSocialNetwork.Application.DTOs.Reaction;
using MiniSocialNetwork.Application.Interfaces;

namespace MiniSocialNetwork.API.Services;

public sealed class SignalRRealtimeNotifier : IRealtimeNotifier
{
    private readonly IHubContext<NotificationHub> _hub;
    public SignalRRealtimeNotifier(IHubContext<NotificationHub> hub) => _hub = hub;

    public Task ReactionChangedAsync(ReactionSummaryResponse summary)
        => _hub.Clients.All.SendAsync("ReactionChanged", summary);

    public Task NotifyUserAsync(string userId, object notification)
        => _hub.Clients.User(userId).SendAsync("ReceiveNotification", notification);
}
