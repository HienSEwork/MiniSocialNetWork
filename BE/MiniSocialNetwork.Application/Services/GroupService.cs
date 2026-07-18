using MiniSocialNetwork.Application.DTOs.Group;
using MiniSocialNetwork.Application.Interfaces;
using MiniSocialNetwork.Application.Interfaces.Repositories;
using MiniSocialNetwork.Domain.Entities;

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
            throw new Exception("Name required");

        var group = new Group
        {
            Id = Guid.NewGuid(),
            Name = req.Name,
            Description = req.Description,
            OwnerId = userId,
            CreatedDate = DateTime.UtcNow
        };

        group.Members.Add(new GroupMember
        {
            GroupId = group.Id,
            UserId = userId,
            Role = 2
        });

        await _repo.AddAsync(group);
        await _repo.SaveChangesAsync();

        return group.Id;
    }

    public async Task JoinGroupAsync(Guid groupId, string userId)
    {
        var group = await _repo.GetByIdAsync(groupId);

        if (group == null)
            throw new Exception("Group not found");

        if (group.Members.Any(x => x.UserId == userId))
            throw new Exception("Already joined");

        group.Members.Add(new GroupMember
        {
            GroupId = groupId,
            UserId = userId,
            Role = 0,
            JoinedDate = DateTime.UtcNow
        });

        await _repo.SaveChangesAsync();
    }
    public async Task Leave(Guid id, string userId)
    {
        var group = await _repo.GetByIdAsync(id);

        if (group.OwnerId == userId)
            throw new Exception("Owner cannot leave");

        var member = group.Members.First(x => x.UserId == userId);

        group.Members.Remove(member);

        await _repo.SaveChangesAsync();
    }

    public async Task Kick(Guid groupId, string targetUserId, string ownerId)
    {
        var group = await _repo.GetByIdAsync(groupId);

        if (group.OwnerId != ownerId)
            throw new Exception("No permission");

        var member = group.Members.First(x => x.UserId == targetUserId);

        group.Members.Remove(member);

        await _repo.SaveChangesAsync();
    }
    public async Task ChangeRole(Guid groupId, string userId, int role, string ownerId)
    {
        var group = await _repo.GetByIdAsync(groupId);

        if (group.OwnerId != ownerId)
            throw new Exception("No permission");

        var member = group.Members.First(x => x.UserId == userId);

        member.Role = role;

        await _repo.SaveChangesAsync();
    }
    public async Task DeleteAsync(Guid id, string userId)
    {
        var group = await _repo.GetByIdAsync(id);

        if (group.OwnerId != userId)
            throw new Exception("Only owner can delete");

        group.IsDeleted = true;

        await _repo.SaveChangesAsync();
    }


    public async Task LeaveGroupAsync(Guid groupId, string userId)
    {
        var group = await _repo.GetByIdAsync(groupId);

        var member = group.Members.FirstOrDefault(x => x.UserId == userId);

        if (member == null)
            throw new Exception("Not a member");

        group.Members.Remove(member);

        await _repo.SaveChangesAsync();
    }

    public async Task<List<GroupResponse>> GetAllAsync()
    {
        var groups = await _repo.GetAllAsync();

        return groups.Select(g => new GroupResponse
        {
            Id = g.Id,
            Name = g.Name
        }).ToList();
    }
}