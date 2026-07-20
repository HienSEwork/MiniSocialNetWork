using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MiniSocialNetwork.Application.DTOs.Story;
using MiniSocialNetwork.Application.Interfaces;

namespace MiniSocialNetwork.API.Controllers;

[Authorize]
[ApiController]
[Route("api/stories")]
public sealed class StoriesController : ControllerBase
{
    private readonly IStoryService _storyService;

    public StoriesController(IStoryService storyService)
    {
        _storyService = storyService;
    }

    [HttpGet]
    public async Task<IActionResult> GetActive()
        => Ok(await _storyService.GetActiveAsync());

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id)
        => Ok(await _storyService.GetByIdAsync(id));

    [HttpPost]
    public async Task<IActionResult> Create(CreateStoryRequest request)
    {
        var id = await _storyService.CreateAsync(request, CurrentUserId);
        return CreatedAtAction(nameof(Get), new { id }, new { id });
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, CreateStoryRequest request)
    {
        await _storyService.UpdateAsync(id, request, CurrentUserId);
        return NoContent();
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        await _storyService.DeleteAsync(id, CurrentUserId);
        return NoContent();
    }

    private string CurrentUserId => User.FindFirstValue(ClaimTypes.NameIdentifier)!;
}
