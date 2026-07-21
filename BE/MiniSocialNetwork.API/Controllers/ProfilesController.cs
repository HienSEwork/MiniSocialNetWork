using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MiniSocialNetwork.Application.DTOs.Auth;
using MiniSocialNetwork.Application.Interfaces;

namespace MiniSocialNetwork.API.Controllers;

[ApiController]
[Route("api/profiles")]
public sealed class ProfilesController : ControllerBase
{
    private readonly IAuthService _authService;

    public ProfilesController(IAuthService authService) => _authService = authService;

    [AllowAnonymous]
    [HttpGet("{userId}")]
    public async Task<ActionResult<UserProfileResponse>> Get(string userId)
        => Ok(await _authService.GetProfileAsync(userId));

    [Authorize]
    [HttpPut("me")]
    public async Task<ActionResult<UserProfileResponse>> Update(UpdateProfileRequest request)
        => Ok(await _authService.UpdateProfileAsync(
            User.FindFirstValue(ClaimTypes.NameIdentifier)!, request));
}
