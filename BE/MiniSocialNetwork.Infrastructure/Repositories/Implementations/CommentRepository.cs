using Microsoft.EntityFrameworkCore;
using MiniSocialNetwork.Application.Interfaces.Repositories;
using MiniSocialNetwork.Domain.Entities;
using MiniSocialNetwork.Infrastructure.Persistence;

namespace MiniSocialNetwork.Infrastructure.Repositories.Implementations;

public sealed class CommentRepository : ICommentRepository
{
    private readonly AppDbContext _context;
    public CommentRepository(AppDbContext context) => _context = context;

    public Task<List<Comment>> GetByPostAsync(Guid postId) => _context.Comments
        .Where(comment => comment.PostId == postId && !comment.IsDeleted)
        .Include(comment => comment.User)
        .OrderBy(comment => comment.CreatedDate)
        .ToListAsync();

    public Task<Comment?> GetByIdAsync(Guid id) => _context.Comments
        .Include(comment => comment.User)
        .FirstOrDefaultAsync(comment => comment.Id == id);

    public Task AddAsync(Comment comment) => _context.Comments.AddAsync(comment).AsTask();
    public void Remove(Comment comment) => comment.IsDeleted = true;
    public Task SaveChangesAsync() => _context.SaveChangesAsync();
}
