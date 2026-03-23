using System.Collections.Concurrent;
using Microsoft.AspNetCore.SignalR;
using SocialNetwork.BLL.Interfaces;
using SocialNetwork.DAL;
using SocialNetwork.Web.Services;

namespace SocialNetwork.Web.Hubs;

public class ChatHub(
    IChatService chatService,
    INotificationService notificationService,
    NotificationBroadcastService notificationBroadcastService,
    ApplicationDbContext dbContext) : Hub
{
    private static readonly ConcurrentDictionary<string, string> ConnectionUsers = new();

    public override async Task OnConnectedAsync()
    {
        var userId = GetRequiredUserId();
        ConnectionUsers[Context.ConnectionId] = userId;
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        ConnectionUsers.TryRemove(Context.ConnectionId, out _);
        await base.OnDisconnectedAsync(exception);
    }

    public async Task JoinGroupChat(Guid groupId)
    {
        var userId = GetRequiredUserId();
        var isMember = dbContext.GroupMembers.Any(member => member.GroupId == groupId && member.UserId == userId);
        if (!isMember)
        {
            throw new HubException("You must join the group before joining its chat.");
        }

        await Groups.AddToGroupAsync(Context.ConnectionId, groupId.ToString());
    }

    public async Task SendPrivateMessage(string receiverId, string content)
    {
        var senderId = GetRequiredUserId();
        var message = await chatService.SavePrivateMessageAsync(senderId, receiverId, content);
        var notifications = await notificationService.CreatePrivateMessageNotificationAsync(
            senderId,
            receiverId,
            $"{message.SenderName}: {content}");

        var receiverConnections = ConnectionUsers
            .Where(pair => pair.Value == receiverId)
            .Select(pair => pair.Key)
            .ToList();

        var senderConnections = ConnectionUsers
            .Where(pair => pair.Value == senderId)
            .Select(pair => pair.Key)
            .ToList();

        await Clients.Clients(receiverConnections.Concat(senderConnections).Distinct())
            .SendAsync("PrivateMessageReceived", message);
        await notificationBroadcastService.BroadcastNotificationsAsync(notifications);
    }

    public async Task SendGroupMessage(Guid groupId, string content)
    {
        var senderId = GetRequiredUserId();
        var message = await chatService.SaveGroupMessageAsync(senderId, groupId, content);

        await Groups.AddToGroupAsync(Context.ConnectionId, groupId.ToString());
        await Clients.Group(groupId.ToString()).SendAsync("GroupMessageReceived", message);
    }

    private string GetRequiredUserId()
    {
        var userId = Context.GetHttpContext()?.Request.Query["userId"].ToString();
        if (string.IsNullOrWhiteSpace(userId))
        {
            throw new HubException("Missing user id.");
        }

        return userId;
    }
}
