using SocialNetwork.DAL.Enums;

namespace SocialNetwork.BLL.Contracts;

public sealed record GroupMemberDto(
    string UserId,
    string DisplayName,
    string? AvatarUrl,
    GroupRole Role,
    DateTime JoinedDate);

public sealed record GroupSummaryDto(
    Guid Id,
    string Name,
    string Description,
    string OwnerId,
    string OwnerName,
    DateTime CreatedDate,
    int MemberCount,
    bool IsJoined,
    bool CanManage);

public sealed record GroupDetailDto(
    GroupSummaryDto Group,
    IReadOnlyList<GroupMemberDto> Members,
    IReadOnlyList<PostFeedItemDto> Posts);

public sealed record CreateGroupRequest(string Name, string Description);

public sealed record UpdateGroupRequest(string Name, string Description);
