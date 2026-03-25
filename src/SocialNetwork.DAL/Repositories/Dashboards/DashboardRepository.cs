using Microsoft.EntityFrameworkCore;

namespace SocialNetwork.DAL.Repositories;

public class DashboardRepository(IDbContextFactory<ApplicationDbContext> dbContextFactory) : IDashboardRepository
{
    public async Task<DashboardSnapshot> GetSnapshotAsync(DateTime cutoff)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        var totalUsers = await dbContext.Users.CountAsync();
        var totalPosts = await dbContext.Posts.CountAsync();
        var totalComments = await dbContext.Comments.CountAsync();
        var totalGroups = await dbContext.Groups.CountAsync();

        var recentPostDates = await dbContext.Posts
            .AsNoTracking()
            .Where(post => post.CreatedDate >= cutoff)
            .Select(post => post.CreatedDate)
            .ToListAsync();

        return new DashboardSnapshot(totalUsers, totalPosts, totalComments, totalGroups, recentPostDates);
    }
}
