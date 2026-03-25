using SocialNetwork.DAL.Entities;

namespace SocialNetwork.DAL.Repositories;

public interface IGroupRepository
{
    Task<IReadOnlyList<Group>> GetGroupsWithOwnerAndMembersAsync();

    Task<Group?> GetGroupWithOwnerAndMembersAsync(Guid groupId);

    Task<Group?> GetGroupSummaryAsync(Guid groupId);

    Task AddGroupAsync(Group group, GroupMember ownerMembership);

    Task<bool> UpdateGroupAsync(Guid groupId, string name, string description);

    Task<bool> SoftDeleteGroupAsync(Guid groupId);

    Task<GroupMember?> GetMembershipAsync(Guid groupId, string userId);

    Task<bool> IsUserMemberAsync(Guid groupId, string userId);

    Task AddMembershipAsync(GroupMember membership);

    Task<bool> RemoveMembershipAsync(Guid groupId, string userId);
}
