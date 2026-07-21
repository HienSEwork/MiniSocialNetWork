using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MiniSocialNetwork.Application.DTOs.Reaction;
using MiniSocialNetwork.Application.Interfaces;

namespace MiniSocialNetwork.API.Controllers;

[ApiController]
[Route("api/posts/{postId:guid}/reactions")]
public sealed class ReactionsController : ControllerBase
{
    private readonly IReactionService _reactionService;
    public ReactionsController(IReactionService reactionService) => _reactionService = reactionService;

    [AllowAnonymous]
    [HttpGet]
    public async Task<IActionResult> Get(Guid postId)
        => Ok(await _reactionService.GetSummaryAsync(postId, User.FindFirstValue(ClaimTypes.NameIdentifier)));

    [Authorize]
    [HttpPost]
    public async Task<IActionResult> Toggle(Guid postId, ToggleReactionRequest request)
        => Ok(await _reactionService.ToggleAsync(postId, request.Type, User.FindFirstValue(ClaimTypes.NameIdentifier)!));
}
