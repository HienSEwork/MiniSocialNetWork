using Microsoft.EntityFrameworkCore;
using SocialNetwork.DAL.Entities;

namespace SocialNetwork.DAL.Repositories;

public class GroupRepository(IDbContextFactory<ApplicationDbContext> dbContextFactory) : IGroupRepository
{
    public async Task<IReadOnlyList<Group>> GetGroupsWithOwnerAndMembersAsync()
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        return await dbContext.Groups
            .AsNoTracking()
            .Include(group => group.Owner)
            .Include(group => group.Members)
            .OrderByDescending(group => group.CreatedDate)
            .ToListAsync();
    }

    public async Task<Group?> GetGroupWithOwnerAndMembersAsync(Guid groupId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        return await dbContext.Groups
            .AsNoTracking()
            .Include(group => group.Owner)
            .Include(group => group.Members)
                .ThenInclude(member => member.User)
            .FirstOrDefaultAsync(group => group.Id == groupId);
    }

    public async Task<Group?> GetGroupSummaryAsync(Guid groupId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        return await dbContext.Groups
            .AsNoTracking()
            .Include(group => group.Owner)
            .Include(group => group.Members)
            .FirstOrDefaultAsync(group => group.Id == groupId);
    }

    public async Task AddGroupAsync(Group group, GroupMember ownerMembership)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        dbContext.Groups.Add(group);
        dbContext.GroupMembers.Add(ownerMembership);
        await dbContext.SaveChangesAsync();
    }

    public async Task<bool> UpdateGroupAsync(Guid groupId, string name, string description)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        var group = await dbContext.Groups.FirstOrDefaultAsync(item => item.Id == groupId);
        if (group is null)
        {
            return false;
        }

        group.Name = name;
        group.Description = description;
        await dbContext.SaveChangesAsync();
        return true;
    }

    public async Task<bool> SoftDeleteGroupAsync(Guid groupId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        var group = await dbContext.Groups.FirstOrDefaultAsync(item => item.Id == groupId);
        if (group is null)
        {
            return false;
        }

        group.IsDeleted = true;
        await dbContext.SaveChangesAsync();
        return true;
    }

    public async Task<GroupMember?> GetMembershipAsync(Guid groupId, string userId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        return await dbContext.GroupMembers
            .AsNoTracking()
            .FirstOrDefaultAsync(member => member.GroupId == groupId && member.UserId == userId);
    }

    public async Task<bool> IsUserMemberAsync(Guid groupId, string userId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        return await dbContext.GroupMembers.AnyAsync(member => member.GroupId == groupId && member.UserId == userId);
    }

    public async Task AddMembershipAsync(GroupMember membership)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        dbContext.GroupMembers.Add(membership);
        await dbContext.SaveChangesAsync();
    }

    public async Task<bool> RemoveMembershipAsync(Guid groupId, string userId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        var membership = await dbContext.GroupMembers.FirstOrDefaultAsync(member => member.GroupId == groupId && member.UserId == userId);
        if (membership is null)
        {
            return false;
        }

        dbContext.GroupMembers.Remove(membership);
        await dbContext.SaveChangesAsync();
        return true;
    }
}
