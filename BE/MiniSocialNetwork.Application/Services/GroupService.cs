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

    public async Task<Guid> CreateGroupAsync(CreateGroupRequest request, string userId)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
            throw new Exception("Group name is required");

        var group = new Group
        {
            Id = Guid.NewGuid(),
            Name = request.Name,
            Description = request.Description,
            OwnerId = userId,
            CreatedDate = DateTime.UtcNow
        };

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