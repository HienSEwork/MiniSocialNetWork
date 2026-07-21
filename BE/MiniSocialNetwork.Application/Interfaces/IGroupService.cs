using MiniSocialNetwork.Application.DTOs.Group;

namespace MiniSocialNetwork.Application.Interfaces;

public interface IGroupService
{
    Task<Guid> CreateGroupAsync(CreateGroupRequest request, string userId);
    Task UpdateGroupAsync(Guid groupId, CreateGroupRequest request, string userId);
    Task DeleteGroupAsync(Guid groupId, string userId);

    Task JoinGroupAsync(Guid groupId, string userId);
    Task LeaveGroupAsync(Guid groupId, string userId);

    Task KickMemberAsync(Guid groupId, string targetUserId, string requesterId);
    Task ChangeRoleAsync(Guid groupId, string targetUserId, int role, string requesterId);

    Task<List<GroupResponse>> GetAllAsync();
    Task<List<GroupResponse>> GetJoinedAsync(string userId);
    Task<GroupResponse?> GetByIdAsync(Guid groupId);
    Task<PagedResult<GroupResponse>> SearchAsync(GroupQuery query);
    Task TransferOwnershipAsync(
    Guid groupId,
    string newOwnerId,
    string requesterId);
}
