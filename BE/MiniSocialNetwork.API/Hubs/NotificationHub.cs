using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace MiniSocialNetwork.API.Hubs;

[Authorize]
public sealed class NotificationHub : Hub;
