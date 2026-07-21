using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MiniSocialNetwork.Application.DTOs.Friend;
using MiniSocialNetwork.Application.Interfaces;

namespace MiniSocialNetwork.API.Controllers;

[ApiController]
[Route("api/friends")]
[Authorize]
public sealed class FriendsController : ControllerBase
{
    private readonly IFriendService _friendService;
    public FriendsController(IFriendService friendService) => _friendService = friendService;
    private string CurrentUserId => User.FindFirstValue(ClaimTypes.NameIdentifier)!;

    // POST api/friends/requests/{addresseeId}
    [HttpPost("requests/{addresseeId}")]
    public async Task<IActionResult> SendRequest(string addresseeId)
    {
        var id = await _friendService.SendRequestAsync(CurrentUserId, addresseeId);
        return CreatedAtAction(nameof(GetIncomingRequests), new { id }, new { id });
    }

    // GET api/friends/requests
    [HttpGet("requests")]
    public async Task<IActionResult> GetIncomingRequests()
        => Ok(await _friendService.GetIncomingRequestsAsync(CurrentUserId));

    // POST api/friends/requests/{requestId}/respond
    [HttpPost("requests/{requestId}/respond")]
    public async Task<IActionResult> RespondRequest(Guid requestId, RespondFriendRequest request)
    {
        await _friendService.RespondRequestAsync(requestId, request.Accept, CurrentUserId);
        return NoContent();
    }

    // GET api/friends
    [HttpGet]
    public async Task<IActionResult> GetFriends()
        => Ok(await _friendService.GetFriendsAsync(CurrentUserId));

    // GET api/friends/search?keyword=...
    [HttpGet("search")]
    public async Task<IActionResult> Search([FromQuery] string? keyword)
        => Ok(await _friendService.SearchUsersAsync(CurrentUserId, keyword));

    // DELETE api/friends/{friendId}
    [HttpDelete("{friendId}")]
    public async Task<IActionResult> RemoveFriend(string friendId)
    {
        await _friendService.RemoveFriendAsync(CurrentUserId, friendId);
        return NoContent();
    }

    // NEW: GET api/friends/recommendations?take=20
    [HttpGet("recommendations")]
    public async Task<IActionResult> Recommendations([FromQuery] int take = 20)
        => Ok(await _friendService.RecommendAsync(CurrentUserId, take));
}
