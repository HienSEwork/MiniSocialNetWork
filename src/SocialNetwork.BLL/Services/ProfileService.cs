using SocialNetwork.BLL.Contracts;
using SocialNetwork.BLL.Interfaces;
using SocialNetwork.DAL.Repositories;

namespace SocialNetwork.BLL.Services;

public class ProfileService(IProfileRepository profileRepository) : IProfileService
{
    public async Task<IReadOnlyList<UserSummaryDto>> GetUsersAsync(string? excludeUserId = null)
    {
        var users = await profileRepository.GetUsersAsync(excludeUserId);

        return users
            .Select(user => new UserSummaryDto(
                user.Id,
                string.IsNullOrWhiteSpace(user.DisplayName) ? user.Email ?? user.UserName ?? "Người dùng" : user.DisplayName,
                user.Email ?? string.Empty,
                user.AvatarUrl,
                user.Bio))
            .ToList();
    }

    public async Task<ProfileDto?> GetProfileAsync(string userId)
    {
        var user = await profileRepository.GetUserAsync(userId);
        if (user is null)
        {
            return null;
        }

        var postCount = await profileRepository.CountPostsByUserAsync(userId);
        var groupCount = await profileRepository.CountGroupMembershipsByUserAsync(userId);

        return new ProfileDto(
            user.Id,
            string.IsNullOrWhiteSpace(user.DisplayName) ? user.Email ?? user.UserName ?? "Người dùng" : user.DisplayName,
            user.Email ?? string.Empty,
            user.AvatarUrl,
            user.Bio,
            user.CreatedDate,
            postCount,
            groupCount);
    }

    public async Task UpdateProfileAsync(string userId, UpdateProfileRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.DisplayName))
        {
            throw new InvalidOperationException("Tên hiển thị là bắt buộc.");
        }

        var user = await profileRepository.GetUserAsync(userId)
            ?? throw new InvalidOperationException("Không tìm thấy người dùng.");

        await profileRepository.UpdateProfileAsync(
            userId,
            request.DisplayName.Trim(),
            string.IsNullOrWhiteSpace(request.AvatarUrl) ? null : request.AvatarUrl.Trim(),
            string.IsNullOrWhiteSpace(request.Bio) ? null : request.Bio.Trim());
    }
}
