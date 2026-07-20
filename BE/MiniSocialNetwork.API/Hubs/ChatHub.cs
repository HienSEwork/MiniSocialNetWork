using Microsoft.AspNetCore.SignalR;
using MiniSocialNetwork.Application.DTOs.Chat;
using MiniSocialNetwork.Application.Interfaces;

namespace MiniSocialNetwork.API.Hubs;

public class ChatHub : Hub
{
    private readonly IChatService _chatService;

    public ChatHub(IChatService chatService)
    {
        _chatService = chatService;
    }

    // Generic SendMessage method used by clients.
    // If groupId is provided -> group message; otherwise a private message to receiverId.
    public async Task<MessageDto> SendMessage(string? receiverId, Guid? groupId, string content)
    {
        var senderId = Context.UserIdentifier
                       ?? Context.GetHttpContext()?.Request.Headers["X-User-Id"].FirstOrDefault()
                       ?? "demo-user";

        var isGroupMessage = groupId.HasValue;

        var dto = await _chatService.SendMessageAsync(senderId, receiverId, groupId, content, isGroupMessage);

        if (isGroupMessage)
        {
            // group name uses groupId string so clients can join by the same string
            var groupName = groupId!.Value.ToString();
            await Clients.Group(groupName).SendAsync("ReceiveGroupMessage", dto);
        }
        else
        {
            if (!string.IsNullOrWhiteSpace(receiverId))
            {
                // deliver to receiver and caller
                await Clients.User(receiverId).SendAsync("ReceivePrivateMessage", dto);
                await Clients.Caller.SendAsync("ReceivePrivateMessage", dto);
            }
            else
            {
                // fallback: send to caller only
                await Clients.Caller.SendAsync("ReceivePrivateMessage", dto);
            }
        }

        return dto;
    }

    // Join group (groupName = groupId.ToString() on clients)
    public Task JoinGroup(string groupName)
        => Groups.AddToGroupAsync(Context.ConnectionId, groupName);

    public Task LeaveGroup(string groupName)
        => Groups.RemoveFromGroupAsync(Context.ConnectionId, groupName);

    // Load private history between current user and another user
    public async Task<List<MessageDto>> GetPrivateHistory(string otherUserId, int limit = 50)
    {
        var currentUser = Context.UserIdentifier
            ?? Context.GetHttpContext()?.Request.Headers["X-User-Id"].FirstOrDefault()
            ?? "demo-user";

        return await _chatService.GetPrivateHistoryAsync(currentUser, otherUserId, limit);
    }

    // Load group history for a given group id
    public async Task<List<MessageDto>> GetGroupHistory(Guid groupId, int limit = 100)
    {
        return await _chatService.GetGroupHistoryAsync(groupId, limit);
    }

    public override Task OnConnectedAsync() => base.OnConnectedAsync();
    public override Task OnDisconnectedAsync(Exception? exception) => base.OnDisconnectedAsync(exception);
}