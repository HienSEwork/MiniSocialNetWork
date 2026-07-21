using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MiniSocialNetwork.Application.DTOs.Auth;
using MiniSocialNetwork.Application.DTOs.Profile;
using MiniSocialNetwork.Application.Interfaces;
using MiniSocialNetwork.Domain.Entities;
using MiniSocialNetwork.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace MiniSocialNetwork.API.Controllers;

[ApiController]
[Route("api/profiles")]
public sealed class ProfilesController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly AppDbContext _context;

    public ProfilesController(IAuthService authService, AppDbContext context)
    {
        _authService = authService;
        _context = context;
    }

    [AllowAnonymous]
    [HttpGet("{userId}")]
    public async Task<ActionResult<UserProfileResponse>> Get(string userId)
        => Ok(await _authService.GetProfileAsync(userId));

    [Authorize]
    [HttpPut("me")]
    public async Task<ActionResult<UserProfileResponse>> Update(UpdateProfileRequest request)
        => Ok(await _authService.UpdateProfileAsync(
            User.FindFirstValue(ClaimTypes.NameIdentifier)!, request));

    [AllowAnonymous]
    [HttpGet("{userId}/portfolio")]
    public async Task<ActionResult<PortfolioResponse>> GetPortfolio(string userId)
    {
        var portfolio = await _context.UserPortfolios.FirstOrDefaultAsync(item => item.UserId == userId);
        if (portfolio == null)
        {
            return Ok(new PortfolioResponse { UserId = userId });
        }
        return Ok(Map(portfolio));
    }

    [Authorize]
    [HttpPut("me/portfolio")]
    public async Task<ActionResult<PortfolioResponse>> UpdatePortfolio(UpdatePortfolioRequest request)
    {
        var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)!;
        var portfolio = await _context.UserPortfolios.FirstOrDefaultAsync(item => item.UserId == userId);
        if (portfolio == null)
        {
            portfolio = new UserPortfolio { UserId = userId };
            await _context.UserPortfolios.AddAsync(portfolio);
        }

        portfolio.Title = request.Title.Trim();
        portfolio.Bio = request.Bio.Trim();
        portfolio.Skills = request.Skills.Trim();
        portfolio.GithubUrl = EmptyToNull(request.GithubUrl);
        portfolio.WebsiteUrl = EmptyToNull(request.WebsiteUrl);
        portfolio.Location = EmptyToNull(request.Location);
        portfolio.FeaturedProjectName = EmptyToNull(request.FeaturedProjectName);
        portfolio.FeaturedProjectUrl = EmptyToNull(request.FeaturedProjectUrl);
        portfolio.UpdatedDate = DateTime.UtcNow;
        await _context.SaveChangesAsync();
        return Ok(Map(portfolio));
    }

    private static PortfolioResponse Map(UserPortfolio portfolio) => new()
    {
        UserId = portfolio.UserId,
        Title = portfolio.Title,
        Bio = portfolio.Bio,
        Skills = portfolio.Skills,
        GithubUrl = portfolio.GithubUrl,
        WebsiteUrl = portfolio.WebsiteUrl,
        Location = portfolio.Location,
        FeaturedProjectName = portfolio.FeaturedProjectName,
        FeaturedProjectUrl = portfolio.FeaturedProjectUrl,
        UpdatedDate = portfolio.UpdatedDate
    };

    private static string? EmptyToNull(string? value)
        => string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}
