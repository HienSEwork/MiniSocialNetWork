using MiniSocialNetwork.Application.DTOs.Group;
using MiniSocialNetwork.Application.Interfaces;
using MiniSocialNetwork.Application.Interfaces.Repositories;
using MiniSocialNetwork.Domain.Entities;
using MiniSocialNetwork.Domain.Enums;

namespace MiniSocialNetwork.Application.Services;

public class GroupService : IGroupService
{
    private readonly IGroupRepository _repo;

    public GroupService(IGroupRepository repo)
    {
        _repo = repo;
    }

    public async Task<Guid> CreateGroupAsync(CreateGroupRequest req, string userId)
    {
        if (string.IsNullOrWhiteSpace(req.Name))
            throw new ArgumentException("Group name is required");

        var group = new Group
        {
            Id = Guid.NewGuid(),
            Name = req.Name.Trim(),
            Description = req.Description,
            OwnerId = userId,
            CreatedDate = DateTime.UtcNow,
            IsDeleted = false
        };

        group.Members.Add(new GroupMember
        {
            GroupId = group.Id,
            UserId = userId,
            Role = (int)GroupRole.Owner,
            JoinedDate = DateTime.UtcNow
        });

        await _repo.AddAsync(group);
        await _repo.SaveChangesAsync();

        return group.Id;
    }

    public async Task UpdateGroupAsync(Guid groupId, CreateGroupRequest req, string userId)
    {
        if (string.IsNullOrWhiteSpace(req.Name))
            throw new ArgumentException("Group name is required");

        var group = await GetActiveGroupAsync(groupId);

        //if (group.OwnerId != userId)
        //    throw new UnauthorizedAccessException("Only the owner can edit this group");

        group.Name = req.Name.Trim();
        group.Description = req.Description;

        await _repo.SaveChangesAsync();
    }

    public async Task DeleteGroupAsync(Guid groupId, string userId)
    {
        var group = await GetActiveGroupAsync(groupId);

        //if (group.OwnerId != userId)
        //    throw new UnauthorizedAccessException("Only the owner can delete this group");

        group.IsDeleted = true;

        await _repo.SaveChangesAsync();
    }

    public async Task JoinGroupAsync(Guid groupId, string userId)
    {
        var group = await GetActiveGroupAsync(groupId);

        if (group.Members.Any(x => x.UserId == userId))
            throw new InvalidOperationException("Already joined");

        group.Members.Add(new GroupMember
        {
            GroupId = groupId,
            UserId = userId,
            Role = (int)GroupRole.Member,
            JoinedDate = DateTime.UtcNow
        });

        await _repo.SaveChangesAsync();
    }

    public async Task LeaveGroupAsync(Guid groupId, string userId)
    {
        var group = await GetActiveGroupAsync(groupId);

        if (group.OwnerId == userId)
            throw new InvalidOperationException("Owner cannot leave the group; transfer ownership or delete it");

        var member = group.Members.FirstOrDefault(x => x.UserId == userId);
        if (member == null)
            throw new InvalidOperationException("Not a member");

        group.Members.Remove(member);

        await _repo.SaveChangesAsync();
    }

    public async Task KickMemberAsync(Guid groupId, string targetUserId, string requesterId)
    {
        var group = await GetActiveGroupAsync(groupId);

        //if (group.OwnerId != requesterId)
        //    throw new UnauthorizedAccessException("Only the owner can remove members");

        if (targetUserId == group.OwnerId)
            throw new InvalidOperationException("Owner cannot be removed");

        var member = group.Members.FirstOrDefault(x => x.UserId == targetUserId);
        if (member == null)
            throw new InvalidOperationException("Member not found");

        group.Members.Remove(member);

        await _repo.SaveChangesAsync();
    }

    public async Task ChangeRoleAsync(Guid groupId, string targetUserId, int role, string requesterId)
    {
        if (!Enum.IsDefined(typeof(GroupRole), role))
            throw new ArgumentException("Invalid role");

        var group = await GetActiveGroupAsync(groupId);

        //if (group.OwnerId != requesterId)
        //    throw new UnauthorizedAccessException("Only the owner can change roles");

        if (targetUserId == group.OwnerId)
            throw new InvalidOperationException("Owner role cannot be changed");

        var member = group.Members.FirstOrDefault(x => x.UserId == targetUserId);
        if (member == null)
            throw new InvalidOperationException("Member not found");

        member.Role = role;

        await _repo.SaveChangesAsync();
    }

    public async Task<List<GroupResponse>> GetAllAsync()
    {
        var groups = await _repo.GetAllAsync();
        return groups.Select(MapToResponse).ToList();
    }

    public async Task<GroupResponse?> GetByIdAsync(Guid groupId)
    {
        var group = await _repo.GetByIdAsync(groupId);
        if (group == null || group.IsDeleted)
            return null;

        return MapToResponse(group);
    }

    public async Task<PagedResult<GroupResponse>> SearchAsync(GroupQuery query)
    {
        var result = await _repo.SearchAsync(query);

        return new PagedResult<GroupResponse>
        {
            Items = result.Items.Select(MapToResponse).ToList(),
            Page = result.Page,
            PageSize = result.PageSize,
            Total = result.Total
        };
    }

    private async Task<Group> GetActiveGroupAsync(Guid groupId)
    {
        var group = await _repo.GetByIdAsync(groupId);
        if (group == null || group.IsDeleted)
            throw new KeyNotFoundException("Group not found");

        return group;
    }

    private static GroupResponse MapToResponse(Group g) => new()
    {
        Id = g.Id,
        Name = g.Name,
        Description = g.Description,
        OwnerId = g.OwnerId,
        MemberCount = g.Members?.Count ?? 0,
        CreatedDate = g.CreatedDate
    };
}
