using Microsoft.EntityFrameworkCore;
using MiniSocialNetwork.Domain.Entities;
using MiniSocialNetwork.Application.DTOs.Group;
using MiniSocialNetwork.Infrastructure.Persistence;
using MiniSocialNetwork.Application.Interfaces.Repositories;

namespace MiniSocialNetwork.Infrastructure.Repositories.Implementations;

public class GroupRepository : IGroupRepository
{
    private readonly AppDbContext _context;

    public GroupRepository(AppDbContext context)
    {
        _context = context;
    }
    public async Task<PagedResult<Group>> SearchAsync(GroupQuery query)
    {
        var page = Math.Max(1, query.Page);
        var pageSize = Math.Clamp(query.PageSize, 1, 50);
        var q = _context.Groups
            .Where(x => !x.IsDeleted)
            .Include(x => x.Members)
            .ThenInclude(member => member.User)
            .AsQueryable();

        // 🔍 SEARCH
        if (!string.IsNullOrWhiteSpace(query.Keyword))
        {
            q = q.Where(x => x.Name.Contains(query.Keyword));
        }

        // 🎯 FILTER OWNER
        if (!string.IsNullOrEmpty(query.OwnerId))
        {
            q = q.Where(x => x.OwnerId == query.OwnerId);
        }

        // 👥 FILTER MEMBER COUNT
        if (query.MinMembers.HasValue)
        {
            q = q.Where(x => x.Members.Count >= query.MinMembers);
        }

        if (query.MaxMembers.HasValue)
        {
            q = q.Where(x => x.Members.Count <= query.MaxMembers);
        }

        // 📊 TOTAL
        var total = await q.CountAsync();

        // 📄 PAGINATION
        var data = await q
            .OrderByDescending(x => x.CreatedDate)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<Group>
        {
            Items = data,
            Total = total,
            Page = page,
            PageSize = pageSize
        };
    }
    public async Task<List<Group>> GetAllAsync()
        => await _context.Groups
            .Where(x => !x.IsDeleted)
            .Include(x => x.Members)
            .ThenInclude(member => member.User)
            .OrderByDescending(x => x.CreatedDate)
            .ToListAsync();

    public async Task<List<Group>> GetJoinedAsync(string userId)
        => await _context.Groups
            .Where(x => !x.IsDeleted && x.Members.Any(member => member.UserId == userId))
            .Include(x => x.Members)
            .ThenInclude(member => member.User)
            .OrderByDescending(x => x.CreatedDate)
            .ToListAsync();

    public async Task<Group?> GetByIdAsync(Guid id)
        => await _context.Groups
            .Include(g => g.Members)
            .ThenInclude(member => member.User)
            .FirstOrDefaultAsync(x => x.Id == id);

    public async Task AddAsync(Group group)
        => await _context.Groups.AddAsync(group);

    public async Task SaveChangesAsync()
        => await _context.SaveChangesAsync();
}
