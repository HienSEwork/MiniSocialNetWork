using SocialNetwork.BLL.Contracts;

namespace SocialNetwork.BLL.Interfaces;

public interface IProfileService
{
    Task<IReadOnlyList<UserSummaryDto>> GetUsersAsync(string? excludeUserId = null);

    Task<ProfileDto?> GetProfileAsync(string userId);

    Task UpdateProfileAsync(string userId, UpdateProfileRequest request);
}
