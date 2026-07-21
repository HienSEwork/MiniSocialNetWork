using Microsoft.EntityFrameworkCore;
using MiniSocialNetwork.Application.Interfaces.Repositories;
using MiniSocialNetwork.Domain.Entities;
using MiniSocialNetwork.Infrastructure.Persistence;

namespace MiniSocialNetwork.Infrastructure.Repositories.Implementations;

public sealed class ReactionRepository : IReactionRepository
{
    private readonly AppDbContext _context;
    public ReactionRepository(AppDbContext context) => _context = context;

    public Task<List<Reaction>> GetByPostAsync(Guid postId)
        => _context.Reactions.Where(reaction => reaction.PostId == postId).ToListAsync();

    public Task<Reaction?> GetUserReactionAsync(Guid postId, string userId)
        => _context.Reactions.FirstOrDefaultAsync(reaction => reaction.PostId == postId && reaction.UserId == userId);

    public Task AddAsync(Reaction reaction) => _context.Reactions.AddAsync(reaction).AsTask();
    public void Remove(Reaction reaction) => _context.Reactions.Remove(reaction);
    public Task SaveChangesAsync() => _context.SaveChangesAsync();
}
