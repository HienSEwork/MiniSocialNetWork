using SocialNetwork.BLL.Contracts;
using SocialNetwork.BLL.Interfaces;
using SocialNetwork.DAL.Entities;
using SocialNetwork.DAL.Enums;
using SocialNetwork.DAL.Repositories;

namespace SocialNetwork.BLL.Services;

public class GroupService(IGroupRepository groupRepository, IPostService postService) : IGroupService
{
    public async Task<IReadOnlyList<GroupSummaryDto>> GetGroupsAsync(string currentUserId)
    {
        var groups = await groupRepository.GetGroupsWithOwnerAndMembersAsync();
        return groups.Select(group => MapSummary(group, currentUserId)).ToList();
    }

    public async Task<GroupDetailDto?> GetGroupDetailAsync(Guid groupId, string currentUserId)
    {
        var group = await groupRepository.GetGroupWithOwnerAndMembersAsync(groupId);
        if (group is null)
        {
            return null;
        }

        var isMember = group.Members.Any(member => member.UserId == currentUserId);
        if (!isMember)
        {
            throw new InvalidOperationException("Bạn phải tham gia nhóm trước khi xem chi tiết.");
        }

        var posts = await postService.GetFeedAsync(currentUserId, groupId);
        return new GroupDetailDto(
            MapSummary(group, currentUserId),
            group.Members
                .OrderBy(member => member.Role)
                .ThenBy(member => member.User.DisplayName)
                .Select(member => new GroupMemberDto(
                    member.UserId,
                    string.IsNullOrWhiteSpace(member.User.DisplayName) ? member.User.Email ?? member.User.UserName ?? "Người dùng" : member.User.DisplayName,
                    member.User.AvatarUrl,
                    member.Role,
                    member.JoinedDate))
                .ToList(),
            posts);
    }

    public async Task<GroupSummaryDto> CreateGroupAsync(string currentUserId, CreateGroupRequest request)
    {
        ValidateGroup(request.Name, request.Description);

        var group = new Group
        {
            Name = request.Name.Trim(),
            Description = request.Description.Trim(),
            OwnerId = currentUserId
        };

        await groupRepository.AddGroupAsync(
            group,
            new GroupMember
            {
                GroupId = group.Id,
                UserId = currentUserId,
                Role = GroupRole.Owner
            });

        return (await GetGroupsAsync(currentUserId)).First(item => item.Id == group.Id);
    }

    public async Task<GroupSummaryDto> UpdateGroupAsync(string currentUserId, Guid groupId, UpdateGroupRequest request)
    {
        ValidateGroup(request.Name, request.Description);

        var group = await groupRepository.GetGroupSummaryAsync(groupId)
            ?? throw new InvalidOperationException("Không tìm thấy nhóm.");

        EnsureCanManage(group, currentUserId);

        await groupRepository.UpdateGroupAsync(groupId, request.Name.Trim(), request.Description.Trim());

        var updatedGroup = await groupRepository.GetGroupSummaryAsync(groupId)
            ?? throw new InvalidOperationException("Không tìm thấy nhóm.");

        return MapSummary(updatedGroup, currentUserId);
    }

    public async Task DeleteGroupAsync(string currentUserId, Guid groupId)
    {
        var group = await groupRepository.GetGroupSummaryAsync(groupId)
            ?? throw new InvalidOperationException("Không tìm thấy nhóm.");

        EnsureCanManage(group, currentUserId);
        await groupRepository.SoftDeleteGroupAsync(groupId);
    }

    public async Task JoinGroupAsync(string currentUserId, Guid groupId)
    {
        var group = await groupRepository.GetGroupSummaryAsync(groupId)
            ?? throw new InvalidOperationException("Không tìm thấy nhóm.");

        var existingMembership = await groupRepository.GetMembershipAsync(group.Id, currentUserId);
        if (existingMembership is not null)
        {
            return;
        }

        await groupRepository.AddMembershipAsync(new GroupMember
        {
            GroupId = groupId,
            UserId = currentUserId,
            Role = GroupRole.Member
        });
    }

    public async Task LeaveGroupAsync(string currentUserId, Guid groupId)
    {
        var membership = await groupRepository.GetMembershipAsync(groupId, currentUserId)
            ?? throw new InvalidOperationException("Không tìm thấy thông tin thành viên trong nhóm.");

        if (membership.Role == GroupRole.Owner)
        {
            throw new InvalidOperationException("Chủ nhóm không thể rời nhóm. Hãy chuyển quyền hoặc xóa nhóm.");
        }

        await groupRepository.RemoveMembershipAsync(groupId, currentUserId);
    }

    private static void ValidateGroup(string name, string description)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            throw new InvalidOperationException("Tên nhóm là bắt buộc.");
        }

        if (string.IsNullOrWhiteSpace(description))
        {
            throw new InvalidOperationException("Mô tả nhóm là bắt buộc.");
        }
    }

    private static void EnsureCanManage(Group group, string currentUserId)
    {
        if (group.OwnerId != currentUserId)
        {
            throw new InvalidOperationException("Chỉ chủ nhóm mới được quản lý nhóm này.");
        }
    }

    private static GroupSummaryDto MapSummary(Group group, string currentUserId) =>
        new(
            group.Id,
            group.Name,
            group.Description,
            group.OwnerId,
            string.IsNullOrWhiteSpace(group.Owner.DisplayName) ? group.Owner.Email ?? group.Owner.UserName ?? "Người dùng" : group.Owner.DisplayName,
            group.CreatedDate,
            group.Members.Count,
            group.Members.Any(member => member.UserId == currentUserId),
            group.OwnerId == currentUserId);
}
