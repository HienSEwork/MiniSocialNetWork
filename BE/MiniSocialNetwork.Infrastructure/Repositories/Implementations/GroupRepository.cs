using Microsoft.EntityFrameworkCore;
using MiniSocialNetwork.Domain.Entities;
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

    public async Task<List<Group>> GetAllAsync()
        => await _context.Groups.ToListAsync();

    public async Task<Group> GetByIdAsync(Guid id)
        => await _context.Groups
            .Include(g => g.Members)
            .FirstOrDefaultAsync(x => x.Id == id);

    public async Task AddAsync(Group group)
        => await _context.Groups.AddAsync(group);

    public async Task SaveChangesAsync()
        => await _context.SaveChangesAsync();
}