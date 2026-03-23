using SocialNetwork.BLL.Contracts;

namespace SocialNetwork.BLL.Interfaces;

public interface IGroupService
{
    Task<IReadOnlyList<GroupSummaryDto>> GetGroupsAsync(string currentUserId);

    Task<GroupDetailDto?> GetGroupDetailAsync(Guid groupId, string currentUserId);

    Task<GroupSummaryDto> CreateGroupAsync(string currentUserId, CreateGroupRequest request);

    Task<GroupSummaryDto> UpdateGroupAsync(string currentUserId, Guid groupId, UpdateGroupRequest request);

    Task DeleteGroupAsync(string currentUserId, Guid groupId);

    Task JoinGroupAsync(string currentUserId, Guid groupId);

    Task LeaveGroupAsync(string currentUserId, Guid groupId);
}
