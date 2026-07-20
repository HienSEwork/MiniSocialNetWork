using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MiniSocialNetwork.Application.DTOs.Post;
using MiniSocialNetwork.Application.Interfaces;

namespace MiniSocialNetwork.API.Controllers;

[ApiController]
[Route("api/groups/{groupId:guid}/posts")]
[Authorize]
public sealed class GroupPostsController : ControllerBase
{
    private readonly IPostService _service;
    public GroupPostsController(IPostService service) => _service = service;
    private string CurrentUserId => User.FindFirstValue(ClaimTypes.NameIdentifier)!;

    [AllowAnonymous, HttpGet]
    public async Task<IActionResult> GetFeed(Guid groupId, [FromQuery] PostQuery query)
        => Ok(await _service.GetGroupFeedAsync(groupId, query));

    [HttpPost]
    public async Task<IActionResult> Create(Guid groupId, CreatePostRequest request)
    {
        var id = await _service.CreateGroupPostAsync(groupId, request, CurrentUserId);
        return CreatedAtAction(nameof(GetFeed), new { groupId }, new { id });
    }

    [HttpDelete("{postId:guid}")]
    public async Task<IActionResult> Delete(Guid groupId, Guid postId)
    {
        await _service.DeleteGroupPostAsync(groupId, postId, CurrentUserId);
        return NoContent();
    }
}
