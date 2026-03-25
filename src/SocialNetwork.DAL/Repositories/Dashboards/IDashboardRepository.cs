namespace SocialNetwork.DAL.Repositories;

public interface IDashboardRepository
{
    Task<DashboardSnapshot> GetSnapshotAsync(DateTime cutoff);
}
