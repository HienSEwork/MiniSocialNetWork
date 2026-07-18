using Microsoft.EntityFrameworkCore;
using MiniSocialNetwork.Application.DTOs.Admin;
using MiniSocialNetwork.Application.Interfaces.Repositories;
using MiniSocialNetwork.Domain.Entities;
using MiniSocialNetwork.Infrastructure.Persistence;

namespace MiniSocialNetwork.Infrastructure.Repositories.Implementations;

public class AdminRepository : IAdminRepository
{
    private readonly AppDbContext _context;

    public AdminRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<DashboardStatsResponse> GetStatsAsync()
    {
        return new DashboardStatsResponse
        {
            TotalUsers = await _context.Users.CountAsync(u => !u.IsDeleted),
            TotalPosts = await _context.Posts.CountAsync(p => !p.IsDeleted),
            TotalComments = await _context.Comments.CountAsync(c => !c.IsDeleted),
            TotalGroups = await _context.Groups.CountAsync(g => !g.IsDeleted)
        };
    }

    public async Task<List<PostsPerDayItem>> GetPostsPerDayAsync(int days)
    {
        if (days < 1) days = 7;

        var since = DateTime.UtcNow.Date.AddDays(-(days - 1));

        return await _context.Posts
            .Where(p => !p.IsDeleted && p.CreatedDate >= since)
            .GroupBy(p => p.CreatedDate.Date)
            .Select(g => new PostsPerDayItem { Date = g.Key, Count = g.Count() })
            .OrderBy(x => x.Date)
            .ToListAsync();
    }

    public async Task<PagedResult<AppUser>> GetUsersAsync(UserQuery query)
    {
        var q = _context.Users
            .Where(u => !u.IsDeleted)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(query.Keyword))
        {
            var kw = query.Keyword.Trim();
            q = q.Where(u =>
                (u.UserName != null && u.UserName.Contains(kw)) ||
                (u.Email != null && u.Email.Contains(kw)) ||
                u.DisplayName.Contains(kw));
        }

        var total = await q.CountAsync();

        var page = query.Page < 1 ? 1 : query.Page;
        var pageSize = query.PageSize < 1 ? 10 : query.PageSize;

        var items = await q
            .OrderByDescending(u => u.CreatedDate)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

        return new PagedResult<AppUser>
        {
            Items = items,
            Total = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<AppUser?> GetUserByIdAsync(string id)
        => await _context.Users.FirstOrDefaultAsync(u => u.Id == id);

    public async Task SaveChangesAsync()
        => await _context.SaveChangesAsync();
}
