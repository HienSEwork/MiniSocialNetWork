namespace SocialNetwork.DAL.Repositories;

public sealed record DashboardSnapshot(
    int TotalUsers,
    int TotalPosts,
    int TotalComments,
    int TotalGroups,
    IReadOnlyList<DateTime> RecentPostDates);
