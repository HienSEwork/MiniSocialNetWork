using Microsoft.EntityFrameworkCore;
using SocialNetwork.BLL.Contracts;
using SocialNetwork.BLL.Interfaces;
using SocialNetwork.DAL;
using SocialNetwork.DAL.Entities;
using SocialNetwork.DAL.Enums;

namespace SocialNetwork.BLL.Services;

public class GroupService(IDbContextFactory<ApplicationDbContext> dbContextFactory, IPostService postService) : IGroupService
{
    public async Task<IReadOnlyList<GroupSummaryDto>> GetGroupsAsync(string currentUserId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        var groups = await dbContext.Groups
            .AsNoTracking()
            .Include(group => group.Owner)
            .Include(group => group.Members)
            .OrderByDescending(group => group.CreatedDate)
            .ToListAsync();

        return groups.Select(group => MapSummary(group, currentUserId)).ToList();
    }

    public async Task<GroupDetailDto?> GetGroupDetailAsync(Guid groupId, string currentUserId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        var group = await dbContext.Groups
            .AsNoTracking()
            .Include(item => item.Owner)
            .Include(item => item.Members)
                .ThenInclude(member => member.User)
            .FirstOrDefaultAsync(item => item.Id == groupId);

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
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        ValidateGroup(request.Name, request.Description);

        var group = new Group
        {
            Name = request.Name.Trim(),
            Description = request.Description.Trim(),
            OwnerId = currentUserId
        };

        dbContext.Groups.Add(group);
        dbContext.GroupMembers.Add(new GroupMember
        {
            GroupId = group.Id,
            UserId = currentUserId,
            Role = GroupRole.Owner
        });

        await dbContext.SaveChangesAsync();

        return (await GetGroupsAsync(currentUserId)).First(item => item.Id == group.Id);
    }

    public async Task<GroupSummaryDto> UpdateGroupAsync(string currentUserId, Guid groupId, UpdateGroupRequest request)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        ValidateGroup(request.Name, request.Description);

        var group = await dbContext.Groups
            .Include(item => item.Owner)
            .Include(item => item.Members)
            .FirstOrDefaultAsync(item => item.Id == groupId)
            ?? throw new InvalidOperationException("Không tìm thấy nhóm.");

        EnsureCanManage(group, currentUserId);

        group.Name = request.Name.Trim();
        group.Description = request.Description.Trim();
        await dbContext.SaveChangesAsync();

        return MapSummary(group, currentUserId);
    }

    public async Task DeleteGroupAsync(string currentUserId, Guid groupId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        var group = await dbContext.Groups.FirstOrDefaultAsync(item => item.Id == groupId)
            ?? throw new InvalidOperationException("Không tìm thấy nhóm.");

        EnsureCanManage(group, currentUserId);
        group.IsDeleted = true;
        await dbContext.SaveChangesAsync();
    }

    public async Task JoinGroupAsync(string currentUserId, Guid groupId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        var group = await dbContext.Groups.FirstOrDefaultAsync(item => item.Id == groupId)
            ?? throw new InvalidOperationException("Không tìm thấy nhóm.");

        var existingMembership = await dbContext.GroupMembers.FindAsync(group.Id, currentUserId);
        if (existingMembership is not null)
        {
            return;
        }

        dbContext.GroupMembers.Add(new GroupMember
        {
            GroupId = groupId,
            UserId = currentUserId,
            Role = GroupRole.Member
        });

        await dbContext.SaveChangesAsync();
    }

    public async Task LeaveGroupAsync(string currentUserId, Guid groupId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        var membership = await dbContext.GroupMembers.FindAsync(groupId, currentUserId)
            ?? throw new InvalidOperationException("Không tìm thấy thông tin thành viên trong nhóm.");

        if (membership.Role == GroupRole.Owner)
        {
            throw new InvalidOperationException("Chủ nhóm không thể rời nhóm. Hãy chuyển quyền hoặc xóa nhóm.");
        }

        dbContext.GroupMembers.Remove(membership);
        await dbContext.SaveChangesAsync();
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
