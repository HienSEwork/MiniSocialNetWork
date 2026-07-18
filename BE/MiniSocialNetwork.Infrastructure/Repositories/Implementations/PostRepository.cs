using Microsoft.EntityFrameworkCore;
using MiniSocialNetwork.Application.DTOs.Post;
using MiniSocialNetwork.Application.Interfaces.Repositories;
using MiniSocialNetwork.Domain.Entities;
using MiniSocialNetwork.Infrastructure.Persistence;

namespace MiniSocialNetwork.Infrastructure.Repositories.Implementations;

public class PostRepository : IPostRepository
{
    private readonly AppDbContext _context;

    public PostRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<PagedResult<Post>> GetGroupFeedAsync(Guid groupId, PostQuery query)
    {
        var q = _context.Posts
            .Where(p => p.GroupId == groupId && !p.IsDeleted)
            .Include(p => p.Comments)
            .Include(p => p.Reactions)
            .OrderByDescending(p => p.CreatedDate)
            .AsQueryable();

        var total = await q.CountAsync();

        var page = query.Page < 1 ? 1 : query.Page;
        var pageSize = query.PageSize < 1 ? 10 : query.PageSize;

        var items = await q
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<Post>
        {
            Items = items,
            Total = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<Post?> GetByIdAsync(Guid id)
        => await _context.Posts
            .Include(p => p.Comments)
            .Include(p => p.Reactions)
            .FirstOrDefaultAsync(p => p.Id == id);

    public async Task AddAsync(Post post)
        => await _context.Posts.AddAsync(post);

    public async Task SaveChangesAsync()
        => await _context.SaveChangesAsync();
}
