namespace SocialNetwork.BLL.Contracts;

public sealed record UserSummaryDto(
    string Id,
    string DisplayName,
    string Email,
    string? AvatarUrl,
    string? Bio);

public sealed record ProfileDto(
    string Id,
    string DisplayName,
    string Email,
    string? AvatarUrl,
    string? Bio,
    DateTime CreatedDate,
    int PostCount,
    int GroupCount);

public sealed record UpdateProfileRequest(
    string DisplayName,
    string? AvatarUrl,
    string? Bio);
