using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MiniSocialNetwork.Application.DTOs.Story;
using MiniSocialNetwork.Application.Interfaces;
using MiniSocialNetwork.Application.DTOs.Chat;

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
        => Ok(await _storyService.GetActiveAsync(CurrentUserId));

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id)
        => Ok(await _storyService.GetByIdAsync(id, CurrentUserId));

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

    [HttpPost("{id:guid}/reactions")]
    public async Task<IActionResult> React(Guid id, StoryReactionRequest request)
        => Ok(await _storyService.ReactAsync(id, request.Type, CurrentUserId));

    [HttpPost("{id:guid}/reply")]
    public async Task<IActionResult> Reply(
        Guid id,
        StoryReplyRequest request,
        [FromServices] IChatService chatService)
    {
        var authorId = await _storyService.GetAuthorIdAsync(id);
        await chatService.SendAsync(CurrentUserId, new SendMessageRequest
        {
            ReceiverId = authorId,
            Content = $"Reply story: {request.Content.Trim()}"
        });
        return NoContent();
    }

    private string CurrentUserId => User.FindFirstValue(ClaimTypes.NameIdentifier)!;
}
