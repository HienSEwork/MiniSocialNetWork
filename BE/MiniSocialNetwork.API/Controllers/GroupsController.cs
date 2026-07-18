using System.Security.Claims;
using Microsoft.AspNetCore.Mvc;
using MiniSocialNetwork.Application.DTOs.Group;
using MiniSocialNetwork.Application.Interfaces;

namespace MiniSocialNetwork.API.Controllers;

[ApiController]
[Route("api/groups")]
public class GroupsController : ControllerBase
{
    private readonly IGroupService _service;

    public GroupsController(IGroupService service)
    {
        _service = service;
    }

    // TODO: rely solely on the authenticated user once JWT auth is wired up.
    // Falls back to an "X-User-Id" header (and finally "demo-user") for local testing.
    private string CurrentUserId =>
        User?.FindFirstValue(ClaimTypes.NameIdentifier)
        ?? Request.Headers["X-User-Id"].FirstOrDefault()
        ?? "demo-user";

    [HttpGet]
    public async Task<IActionResult> GetAll()
        => Ok(await _service.GetAllAsync());

    [HttpGet("search")]
    public async Task<IActionResult> Search([FromQuery] GroupQuery query)
        => Ok(await _service.SearchAsync(query));

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var group = await _service.GetByIdAsync(id);
        return group == null ? NotFound() : Ok(group);
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateGroupRequest request)
    {
        var id = await _service.CreateGroupAsync(request, CurrentUserId);
        return CreatedAtAction(nameof(GetById), new { id }, id);
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, [FromBody] CreateGroupRequest request)
    {
        await _service.UpdateGroupAsync(id, request, CurrentUserId);
        return NoContent();
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        await _service.DeleteGroupAsync(id, CurrentUserId);
        return NoContent();
    }

    [HttpPost("{id:guid}/join")]
    public async Task<IActionResult> Join(Guid id)
    {
        await _service.JoinGroupAsync(id, CurrentUserId);
        return Ok();
    }

    [HttpPost("{id:guid}/leave")]
    public async Task<IActionResult> Leave(Guid id)
    {
        await _service.LeaveGroupAsync(id, CurrentUserId);
        return Ok();
    }

    [HttpDelete("{id:guid}/members/{userId}")]
    public async Task<IActionResult> Kick(Guid id, string userId)
    {
        await _service.KickMemberAsync(id, userId, CurrentUserId);
        return NoContent();
    }

    [HttpPut("{id:guid}/members/{userId}/role")]
    public async Task<IActionResult> ChangeRole(Guid id, string userId, [FromBody] ChangeRoleRequest request)
    {
        await _service.ChangeRoleAsync(id, userId, request.Role, CurrentUserId);
        return NoContent();
    }
}
