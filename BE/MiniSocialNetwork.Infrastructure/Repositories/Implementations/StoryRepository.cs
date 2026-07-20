using Microsoft.EntityFrameworkCore;
using MiniSocialNetwork.Application.Interfaces.Repositories;
using MiniSocialNetwork.Domain.Entities;
using MiniSocialNetwork.Infrastructure.Persistence;

namespace MiniSocialNetwork.Infrastructure.Repositories.Implementations;

public sealed class StoryRepository : IStoryRepository
{
    private readonly AppDbContext _context;

    public StoryRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<List<Story>> GetActiveAsync()
        => await _context.Stories
            .Include(story => story.User)
            .Where(story => !story.IsDeleted && story.ExpiresAt > DateTime.UtcNow)
            .OrderByDescending(story => story.CreatedDate)
            .Take(60)
            .ToListAsync();

    public async Task<Story?> GetByIdAsync(Guid id)
        => await _context.Stories
            .Include(story => story.User)
            .FirstOrDefaultAsync(story => story.Id == id);

    public async Task AddAsync(Story story)
        => await _context.Stories.AddAsync(story);

    public async Task SaveChangesAsync()
        => await _context.SaveChangesAsync();
}
