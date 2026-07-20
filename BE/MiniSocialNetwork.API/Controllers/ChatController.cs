using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using MiniSocialNetwork.API.Hubs;
using MiniSocialNetwork.Application.DTOs.Chat;
using MiniSocialNetwork.Application.Interfaces;

namespace MiniSocialNetwork.API.Controllers;

[ApiController]
[Route("api/chat")]
public class ChatController : ControllerBase
{
    private readonly IChatService _chatService;
    private readonly IHubContext<ChatHub> _chatHub;
    private readonly IHubContext<NotificationHub> _notificationHub;

    public ChatController(
        IChatService chatService,
        IHubContext<ChatHub> chatHub,
        IHubContext<NotificationHub> notificationHub)
    {
        _chatService = chatService;
        _chatHub = chatHub;
        _notificationHub = notificationHub;
    }

    // Same fallback as other controllers: authenticated user -> X-User-Id header -> "demo-user"
    private string CurrentUserId =>
        User?.FindFirstValue(ClaimTypes.NameIdentifier)
        ?? Request.Headers["X-User-Id"].FirstOrDefault()
        ?? "demo-user";

    /// <summary>
    /// Send a message (private or group). Body: receiverId OR groupId + content.
    /// Returns the saved message DTO.
    /// Also pushes the message to connected SignalR clients.
    /// </summary>
    [HttpPost("send")]
    public async Task<IActionResult> Send([FromBody] SendMessageRequest request)
    {
        if (request == null || string.IsNullOrWhiteSpace(request.Content))
            return BadRequest("Content is required.");

        var isGroup = request.GroupId.HasValue;
        var message = await _chatService.SendMessageAsync(
            senderId: CurrentUserId,
            receiverId: request.ReceiverId,
            groupId: request.GroupId,
            content: request.Content,
            isGroupMessage: isGroup);

        // Broadcast to SignalR clients
        if (isGroup)
        {
            var groupName = request.GroupId!.Value.ToString();
            await _chatHub.Clients.Group(groupName).SendAsync("ReceiveGroupMessage", message);
        }
        else
        {
            if (!string.IsNullOrWhiteSpace(request.ReceiverId))
            {
                // send to receiver and to sender to keep UI in sync
                await _chatHub.Clients.User(request.ReceiverId).SendAsync("ReceivePrivateMessage", message);
                await _chatHub.Clients.User(CurrentUserId).SendAsync("ReceivePrivateMessage", message);

                // optional: notify the receiver via notification hub
                await _notificationHub.Clients.User(request.ReceiverId)
                    .SendAsync("ReceiveNotification", "New message", $"New message from {CurrentUserId}");
            }
            else
            {
                // no receiver specified -> return created message only
                await _chatHub.Clients.User(CurrentUserId).SendAsync("ReceivePrivateMessage", message);
            }
        }

        return Ok(message);
    }

    /// <summary>
    /// Get private chat history between current user and otherUserId (most recent first by default limit),
    /// returned ordered ascending by CreatedDate.
    /// </summary>
    [HttpGet("private/{otherUserId}")]
    public async Task<IActionResult> GetPrivateHistory(string otherUserId, [FromQuery] int limit = 50)
    {
        if (string.IsNullOrWhiteSpace(otherUserId))
            return BadRequest("otherUserId is required.");

        var list = await _chatService.GetPrivateHistoryAsync(CurrentUserId, otherUserId, limit);
        return Ok(list);
    }

    /// <summary>
    /// Get group chat history for a group.
    /// </summary>
    [HttpGet("group/{groupId:guid}")]
    public async Task<IActionResult> GetGroupHistory(Guid groupId, [FromQuery] int limit = 100)
    {
        var list = await _chatService.GetGroupHistoryAsync(groupId, limit);
        return Ok(list);
    }

    /// <summary>
    /// Convenience DTO for send endpoint.
    /// </summary>
    public class SendMessageRequest
    {
        public string? ReceiverId { get; set; }         // target user for private messages
        public Guid? GroupId { get; set; }              // target group for group messages
        public string Content { get; set; } = string.Empty;
    }
}
