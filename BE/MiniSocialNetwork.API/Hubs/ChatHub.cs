using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Collections.Concurrent;
using MiniSocialNetwork.Application.DTOs.Chat;
using MiniSocialNetwork.Application.Interfaces;

namespace MiniSocialNetwork.API.Hubs;

[Authorize]
public sealed class ChatHub : Hub
{
    private static readonly ConcurrentDictionary<string, int> Connections = new();
    private readonly IChatService _chatService;
    public ChatHub(IChatService chatService) => _chatService = chatService;

    public async Task SendMessage(SendMessageRequest request)
    {
        var senderId = Context.User!.FindFirstValue(ClaimTypes.NameIdentifier)!;
        var message = await _chatService.SendAsync(senderId, request);
        if (message.IsGroupMessage)
            await Clients.Group(GroupName(message.GroupId!.Value)).SendAsync("ReceiveMessage", message);
        else
        {
            await Clients.User(message.ReceiverId!).SendAsync("ReceiveMessage", message);
            await Clients.Caller.SendAsync("ReceiveMessage", message);
        }
    }

    public async Task JoinGroup(Guid groupId)
    {
        var userId = Context.User!.FindFirstValue(ClaimTypes.NameIdentifier)!;
        await _chatService.EnsureGroupMemberAsync(groupId, userId);
        await Groups.AddToGroupAsync(Context.ConnectionId, GroupName(groupId));
    }

    public override async Task OnConnectedAsync()
    {
        var userId = Context.User!.FindFirstValue(ClaimTypes.NameIdentifier)!;
        Connections.AddOrUpdate(userId, 1, (_, count) => count + 1);
        await Clients.All.SendAsync("UserPresenceChanged", new { userId, isOnline = true });
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = Context.User!.FindFirstValue(ClaimTypes.NameIdentifier)!;
        var remaining = Connections.AddOrUpdate(userId, 0, (_, count) => Math.Max(0, count - 1));
        if (remaining == 0)
        {
            Connections.TryRemove(userId, out _);
            await Clients.All.SendAsync("UserPresenceChanged", new { userId, isOnline = false });
        }
        await base.OnDisconnectedAsync(exception);
    }

    private static string GroupName(Guid groupId) => $"group:{groupId}";
}
