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

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        return Ok(await _service.GetAllAsync());
    }

    [HttpPost]
    public async Task<IActionResult> Create(CreateGroupRequest request)
    {
        var userId = "demo-user";
        var id = await _service.CreateGroupAsync(request, userId);

        return Ok(id);
    }

    [HttpPost("{id}/join")]
    public async Task<IActionResult> Join(Guid id)
    {
        var userId = "demo-user";
        await _service.JoinGroupAsync(id, userId);

        return Ok();
    }
}