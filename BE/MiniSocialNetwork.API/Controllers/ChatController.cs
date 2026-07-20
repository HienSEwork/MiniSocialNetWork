using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MiniSocialNetwork.Application.DTOs.Chat;
using MiniSocialNetwork.Application.Interfaces;

namespace MiniSocialNetwork.API.Controllers;

[Authorize]
[ApiController]
[Route("api/chat")]
public sealed class ChatController : ControllerBase
{
    private readonly IChatService _chatService;
    public ChatController(IChatService chatService) => _chatService = chatService;

    [HttpGet("users")]
    public async Task<IActionResult> Users([FromQuery] string? keyword)
        => Ok(await _chatService.GetUsersAsync(CurrentUserId, keyword));

    [HttpGet("private/{otherUserId}")]
    public async Task<IActionResult> PrivateHistory(string otherUserId, [FromQuery] int take = 100)
        => Ok(await _chatService.GetPrivateHistoryAsync(CurrentUserId, otherUserId, take));

    [HttpGet("groups/{groupId:guid}")]
    public async Task<IActionResult> GroupHistory(Guid groupId, [FromQuery] int take = 100)
        => Ok(await _chatService.GetGroupHistoryAsync(CurrentUserId, groupId, take));

    [HttpPost("messages")]
    public async Task<IActionResult> Send(SendMessageRequest request)
        => Ok(await _chatService.SendAsync(CurrentUserId, request));

    private string CurrentUserId => User.FindFirstValue(ClaimTypes.NameIdentifier)!;
}
