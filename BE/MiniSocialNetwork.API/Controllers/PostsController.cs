using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MiniSocialNetwork.Application.DTOs.Post;
using MiniSocialNetwork.Application.Interfaces;

namespace MiniSocialNetwork.API.Controllers;

[ApiController]
[Route("api/posts")]
public sealed class PostsController : ControllerBase
{
    private readonly IPostService _postService;

    public PostsController(IPostService postService) => _postService = postService;

    [HttpGet]
    public async Task<IActionResult> Feed([FromQuery] PostQuery query)
        => Ok(await _postService.GetFeedAsync(query, CurrentUserId));

    [AllowAnonymous]
    [HttpGet("{id:guid}")]
    public async Task<IActionResult> Get(Guid id) => Ok(await _postService.GetByIdAsync(id));

    [Authorize]
    [HttpPost]
    public async Task<IActionResult> Create(CreatePostRequest request)
    {
        var id = await _postService.CreateAsync(request, CurrentUserId);
        return CreatedAtAction(nameof(Get), new { id }, new { id });
    }

    [Authorize]
    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, CreatePostRequest request)
    {
        await _postService.UpdateAsync(id, request, CurrentUserId);
        return NoContent();
    }

    [Authorize]
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        await _postService.DeleteAsync(id, CurrentUserId);
        return NoContent();
    }

    private string CurrentUserId => User.FindFirstValue(ClaimTypes.NameIdentifier)!;
}
