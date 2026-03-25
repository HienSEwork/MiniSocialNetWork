using SocialNetwork.DAL.Entities;

namespace SocialNetwork.DAL.Repositories;

public interface IProfileRepository
{
    Task<IReadOnlyList<ApplicationUser>> GetUsersAsync(string? excludeUserId = null);

    Task<ApplicationUser?> GetUserAsync(string userId);

    Task<int> CountPostsByUserAsync(string userId);

    Task<int> CountGroupMembershipsByUserAsync(string userId);

    Task<bool> UpdateProfileAsync(string userId, string displayName, string? avatarUrl, string? bio);
}
