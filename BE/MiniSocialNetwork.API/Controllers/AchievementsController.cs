using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MiniSocialNetwork.Application.DTOs.Achievement;
using MiniSocialNetwork.Domain.Entities;
using MiniSocialNetwork.Infrastructure.Persistence;

namespace MiniSocialNetwork.API.Controllers;

[ApiController]
[Route("api")]
public sealed class AchievementsController : ControllerBase
{
    private readonly AppDbContext _context;

    public AchievementsController(AppDbContext context)
    {
        _context = context;
    }

    [Authorize]
    [HttpGet("achievements/me")]
    public async Task<ActionResult<IReadOnlyCollection<AchievementResponse>>> Me()
        => Ok(await GetForUserAsync(CurrentUserId, materialize: true));

    [AllowAnonymous]
    [HttpGet("profiles/{userId}/achievements")]
    public async Task<ActionResult<IReadOnlyCollection<AchievementResponse>>> Profile(string userId)
    {
        Console.WriteLine($"Achievements.Profile invoked for userId={userId}");
        var result = await GetForUserAsync(userId, materialize: false);
        Console.WriteLine($"Achievements.Profile returning {result?.Count ?? 0} items for {userId}");
        return Ok(result);
    }

    private async Task<IReadOnlyCollection<AchievementResponse>> GetForUserAsync(
        string userId,
        bool materialize)
    {
        await EnsureDefinitionsAsync();
        if (materialize) await UnlockCurrentAchievementsAsync(userId);

        var definitions = await _context.AchievementDefinitions
            .Where(item => item.IsActive)
            .OrderBy(item => item.SortOrder)
            .ToListAsync();
        var unlocked = await _context.UserAchievements
            .Where(item => item.UserId == userId)
            .ToDictionaryAsync(item => item.AchievementCode, item => item.UnlockedAt);

        return definitions.Select(item => new AchievementResponse
        {
            Code = item.Code,
            Name = item.Name,
            Description = item.Description,
            Icon = item.Icon,
            Unlocked = unlocked.ContainsKey(item.Code),
            UnlockedAt = unlocked.TryGetValue(item.Code, out var date) ? date : null
        }).ToArray();
    }

    private async Task UnlockCurrentAchievementsAsync(string userId)
    {
        var unlocks = new List<string>();
        if (await _context.Posts.AnyAsync(item => item.UserId == userId && !item.IsDeleted))
            unlocks.Add("first-post");
        if (await _context.Stories.AnyAsync(item => item.UserId == userId && !item.IsDeleted))
            unlocks.Add("first-story");
        if (await _context.GroupMembers.AnyAsync(item => item.UserId == userId))
            unlocks.Add("joined-group");
        if (await _context.UserPortfolios.AnyAsync(item =>
                item.UserId == userId &&
                (item.Title != "" || item.Skills != "" || item.FeaturedProjectName != null)))
            unlocks.Add("portfolio-ready");
        if (await _context.Reactions.AnyAsync(reaction =>
                _context.Posts.Any(post => post.Id == reaction.PostId && post.UserId == userId)))
            unlocks.Add("got-reaction");

        foreach (var code in unlocks.Distinct())
        {
            var exists = await _context.UserAchievements.AnyAsync(item =>
                item.UserId == userId && item.AchievementCode == code);
            if (exists) continue;
            await _context.UserAchievements.AddAsync(new UserAchievement
            {
                UserId = userId,
                AchievementCode = code,
                UnlockedAt = DateTime.UtcNow
            });
        }
        await _context.SaveChangesAsync();
    }

    private async Task EnsureDefinitionsAsync()
    {
        if (await _context.AchievementDefinitions.AnyAsync()) return;
        var definitions = new[]
        {
            new AchievementDefinition { Code = "first-post", Name = "Bài viết đầu tiên", Description = "Đăng bài đầu tiên trong cộng đồng.", Icon = "edit_note", SortOrder = 1 },
            new AchievementDefinition { Code = "first-story", Name = "Story đầu tiên", Description = "Chia sẻ story đầu tiên trên TechNet.", Icon = "auto_awesome", SortOrder = 2 },
            new AchievementDefinition { Code = "joined-group", Name = "Thành viên cộng đồng", Description = "Tham gia ít nhất một nhóm.", Icon = "groups", SortOrder = 3 },
            new AchievementDefinition { Code = "portfolio-ready", Name = "Portfolio sẵn sàng", Description = "Hoàn thiện vai trò, kỹ năng hoặc project nổi bật.", Icon = "workspaces", SortOrder = 4 },
            new AchievementDefinition { Code = "got-reaction", Name = "Được quan tâm", Description = "Bài viết của bạn đã nhận reaction.", Icon = "favorite", SortOrder = 5 }
        };
        await _context.AchievementDefinitions.AddRangeAsync(definitions);
        await _context.SaveChangesAsync();
    }

    private string CurrentUserId => User.FindFirstValue(ClaimTypes.NameIdentifier)!;
}
