using Microsoft.EntityFrameworkCore;
using MiniSocialNetwork.Application.Interfaces.Repositories;
using MiniSocialNetwork.Infrastructure.Persistence;

namespace MiniSocialNetwork.Infrastructure.Repositories.Implementations;

public sealed class SearchRepository : ISearchRepository
{
    private readonly AppDbContext _context;

    public SearchRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<SearchRepositoryResult> SearchAsync(string query, int limit)
    {
        var usersQuery = _context.Users
            .AsNoTracking()
            .Where(user => !user.IsDeleted &&
                (user.DisplayName.Contains(query) ||
                 (user.Bio != null && user.Bio.Contains(query))));
        var userTotal = await usersQuery.CountAsync();
        var users = await usersQuery
            .OrderByDescending(user => user.DisplayName.StartsWith(query))
            .ThenBy(user => user.DisplayName)
            .Take(limit)
            .ToListAsync();

        var groupsQuery = _context.Groups
            .AsNoTracking()
            .Where(group => !group.IsDeleted &&
                (group.Name.Contains(query) || group.Description.Contains(query)));
        var groupTotal = await groupsQuery.CountAsync();
        var groups = await groupsQuery
            .Include(group => group.Members)
            .OrderByDescending(group => group.Name.StartsWith(query))
            .ThenByDescending(group => group.Members.Count)
            .ThenBy(group => group.Name)
            .Take(limit)
            .ToListAsync();

        var postsQuery = _context.Posts
            .AsNoTracking()
            .Where(post => !post.IsDeleted && !post.User.IsDeleted &&
                (post.Group == null || !post.Group.IsDeleted) &&
                (post.Content.Contains(query) ||
                 post.User.DisplayName.Contains(query) ||
                 (post.Group != null && post.Group.Name.Contains(query))));
        var postTotal = await postsQuery.CountAsync();
        var posts = await postsQuery
            .Include(post => post.User)
            .Include(post => post.Group)
            .Include(post => post.Comments)
            .Include(post => post.Reactions)
            .OrderByDescending(post => post.Content.StartsWith(query))
            .ThenByDescending(post => post.CreatedDate)
            .Take(limit)
            .ToListAsync();

        return new SearchRepositoryResult
        {
            UserTotal = userTotal,
            GroupTotal = groupTotal,
            PostTotal = postTotal,
            Users = users,
            Groups = groups,
            Posts = posts
        };
    }
}
