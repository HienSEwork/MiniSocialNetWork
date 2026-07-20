using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MiniSocialNetwork.Application.DTOs.Comment;
using MiniSocialNetwork.Application.Interfaces;

namespace MiniSocialNetwork.API.Controllers;

[ApiController]
[Route("api/posts/{postId:guid}/comments")]
public sealed class CommentsController : ControllerBase
{
    private readonly ICommentService _commentService;
    public CommentsController(ICommentService commentService) => _commentService = commentService;

    [AllowAnonymous]
    [HttpGet]
    public async Task<IActionResult> Get(Guid postId) => Ok(await _commentService.GetByPostAsync(postId));

    [Authorize]
    [HttpPost]
    public async Task<IActionResult> Create(Guid postId, CommentRequest request)
    {
        var comment = await _commentService.CreateAsync(postId, request, CurrentUserId);
        return Created($"api/posts/{postId}/comments/{comment.Id}", comment);
    }

    [Authorize]
    [HttpPut("{commentId:guid}")]
    public async Task<IActionResult> Update(Guid postId, Guid commentId, CommentRequest request)
        => Ok(await _commentService.UpdateAsync(commentId, request, CurrentUserId));

    [Authorize]
    [HttpDelete("{commentId:guid}")]
    public async Task<IActionResult> Delete(Guid postId, Guid commentId)
    {
        await _commentService.DeleteAsync(commentId, CurrentUserId);
        return NoContent();
    }

    private string CurrentUserId => User.FindFirstValue(ClaimTypes.NameIdentifier)!;
}
