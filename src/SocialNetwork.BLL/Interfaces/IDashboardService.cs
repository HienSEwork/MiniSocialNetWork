using SocialNetwork.BLL.Contracts;

namespace SocialNetwork.BLL.Interfaces;

public interface IDashboardService
{
    Task<DashboardStatsDto> GetStatsAsync();
}
