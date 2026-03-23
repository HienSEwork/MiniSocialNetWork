namespace SocialNetwork.BLL.Contracts;

public sealed record DailyPostPoint(DateOnly Day, int TotalPosts);

public sealed record DashboardStatsDto(
    int TotalUsers,
    int TotalPosts,
    int TotalComments,
    int TotalGroups,
    IReadOnlyList<DailyPostPoint> PostsPerDay);
