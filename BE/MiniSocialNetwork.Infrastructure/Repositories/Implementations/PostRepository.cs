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

    public Task<PagedResult<Post>> GetFeedAsync(PostQuery query, string userId)
        => PageAsync(
            _context.Posts.Where(post =>
                !post.IsDeleted &&
                post.GroupId.HasValue &&
                post.Group!.Members.Any(member => member.UserId == userId)),
            query);

    public async Task<PagedResult<Post>> GetGroupFeedAsync(Guid groupId, PostQuery query)
    {
        return await PageAsync(
            _context.Posts.Where(p => p.GroupId == groupId && !p.IsDeleted), query);
    }

    public async Task<Post?> GetByIdAsync(Guid id)
        => await _context.Posts
            .Include(p => p.Comments)
            .Include(p => p.Reactions)
            .Include(p => p.User)
            .Include(p => p.Group)
            .FirstOrDefaultAsync(p => p.Id == id);

    public async Task AddAsync(Post post)
        => await _context.Posts.AddAsync(post);

    public async Task SaveChangesAsync()
        => await _context.SaveChangesAsync();

    private static async Task<PagedResult<Post>> PageAsync(IQueryable<Post> queryable, PostQuery query)
    {
        var page = Math.Max(1, query.Page);
        var pageSize = Math.Clamp(query.PageSize, 1, 50);
        var queryWithIncludes = queryable
            .Include(p => p.Comments)
            .Include(p => p.Reactions)
            .Include(p => p.User)
            .Include(p => p.Group)
            .OrderByDescending(p => p.CreatedDate);
        var total = await queryWithIncludes.CountAsync();
        var items = await queryWithIncludes.Skip((page - 1) * pageSize).Take(pageSize).ToListAsync();
        return new PagedResult<Post> { Items = items, Total = total, Page = page, PageSize = pageSize };
    }
}
