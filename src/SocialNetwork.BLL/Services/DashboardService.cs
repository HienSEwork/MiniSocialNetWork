using Microsoft.EntityFrameworkCore;
using SocialNetwork.BLL.Contracts;
using SocialNetwork.BLL.Interfaces;
using SocialNetwork.DAL;

namespace SocialNetwork.BLL.Services;

public class DashboardService(IDbContextFactory<ApplicationDbContext> dbContextFactory) : IDashboardService
{
    public async Task<DashboardStatsDto> GetStatsAsync()
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        var totalUsers = await dbContext.Users.CountAsync();
        var totalPosts = await dbContext.Posts.CountAsync();
        var totalComments = await dbContext.Comments.CountAsync();
        var totalGroups = await dbContext.Groups.CountAsync();

        var cutoff = DateTime.UtcNow.Date.AddDays(-6);
        var postsPerDayRaw = await dbContext.Posts
            .Where(post => post.CreatedDate >= cutoff)
            .ToListAsync();

        var postsPerDayLookup = postsPerDayRaw
            .GroupBy(post => DateOnly.FromDateTime(post.CreatedDate))
            .ToDictionary(group => group.Key, group => group.Count());

        var normalized = Enumerable.Range(0, 7)
            .Select(offset => DateOnly.FromDateTime(cutoff.AddDays(offset)))
            .Select(day => new DailyPostPoint(day, postsPerDayLookup.GetValueOrDefault(day)))
            .ToList();

        return new DashboardStatsDto(totalUsers, totalPosts, totalComments, totalGroups, normalized);
    }
}
