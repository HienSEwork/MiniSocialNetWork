using SocialNetwork.BLL.Contracts;
using SocialNetwork.BLL.Interfaces;
using SocialNetwork.DAL.Repositories;

namespace SocialNetwork.BLL.Services;

public class DashboardService(IDashboardRepository dashboardRepository) : IDashboardService
{
    public async Task<DashboardStatsDto> GetStatsAsync()
    {
        var cutoff = DateTime.UtcNow.Date.AddDays(-6);
        var snapshot = await dashboardRepository.GetSnapshotAsync(cutoff);

        var postsPerDayLookup = snapshot.RecentPostDates
            .GroupBy(createdDate => DateOnly.FromDateTime(createdDate))
            .ToDictionary(group => group.Key, group => group.Count());

        var normalized = Enumerable.Range(0, 7)
            .Select(offset => DateOnly.FromDateTime(cutoff.AddDays(offset)))
            .Select(day => new DailyPostPoint(day, postsPerDayLookup.GetValueOrDefault(day)))
            .ToList();

        return new DashboardStatsDto(
            snapshot.TotalUsers,
            snapshot.TotalPosts,
            snapshot.TotalComments,
            snapshot.TotalGroups,
            normalized);
    }
}
