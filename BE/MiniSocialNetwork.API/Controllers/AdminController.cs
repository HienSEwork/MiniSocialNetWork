using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MiniSocialNetwork.Application.DTOs.Admin;
using MiniSocialNetwork.Application.Interfaces;

namespace MiniSocialNetwork.API.Controllers;

[ApiController]
[Route("api/admin")]
[Authorize(Roles = "Admin")]
public sealed class AdminController : ControllerBase
{
    private readonly IAdminService _service;
    public AdminController(IAdminService service) => _service = service;

    [HttpGet("stats")]
    public async Task<IActionResult> GetStats() => Ok(await _service.GetStatsAsync());

    [HttpGet("posts-per-day")]
    public async Task<IActionResult> GetPostsPerDay([FromQuery] int days = 7)
        => Ok(await _service.GetPostsPerDayAsync(days));

    [HttpGet("users")]
    public async Task<IActionResult> GetUsers([FromQuery] UserQuery query) => Ok(await _service.GetUsersAsync(query));

    [HttpDelete("users/{userId}")]
    public async Task<IActionResult> DeleteUser(string userId)
    {
        await _service.DeleteUserAsync(userId);
        return NoContent();
    }
}
