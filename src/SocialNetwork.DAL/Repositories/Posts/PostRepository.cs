using Microsoft.EntityFrameworkCore;
using SocialNetwork.DAL.Entities;
using SocialNetwork.DAL.Enums;

namespace SocialNetwork.DAL.Repositories;

public class PostRepository(IDbContextFactory<ApplicationDbContext> dbContextFactory) : IPostRepository
{
    public async Task<bool> IsUserMemberOfGroupAsync(string userId, Guid groupId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        return await dbContext.GroupMembers.AnyAsync(member => member.GroupId == groupId && member.UserId == userId);
    }

    public async Task<IReadOnlyList<Post>> GetFeedPostsAsync(string currentUserId, Guid? groupId = null)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        List<Guid> joinedGroupIds = [];

        if (!groupId.HasValue)
        {
            joinedGroupIds = await dbContext.GroupMembers
                .AsNoTracking()
                .Where(member => member.UserId == currentUserId)
                .Select(member => member.GroupId)
                .ToListAsync();
        }

        return await BuildPostDetailsQuery(dbContext)
            .Where(post => groupId.HasValue
                ? post.GroupId == groupId
                : post.GroupId == null || (post.GroupId.HasValue && joinedGroupIds.Contains(post.GroupId.Value)))
            .OrderByDescending(post => post.CreatedDate)
            .ToListAsync();
    }

    public async Task<IReadOnlyCollection<Guid>> GetSavedPostIdsAsync(string currentUserId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        return await dbContext.SavedPosts
            .AsNoTracking()
            .Where(savedPost => savedPost.UserId == currentUserId)
            .Select(savedPost => savedPost.PostId)
            .ToListAsync();
    }

    public async Task<IReadOnlyList<SavedPost>> GetSavedPostsAsync(string currentUserId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        var joinedGroupIds = await dbContext.GroupMembers
            .AsNoTracking()
            .Where(member => member.UserId == currentUserId)
            .Select(member => member.GroupId)
            .ToListAsync();

        return await dbContext.SavedPosts
            .AsNoTracking()
            .Where(savedPost => savedPost.UserId == currentUserId)
            .Include(savedPost => savedPost.Post)
                .ThenInclude(post => post.User)
            .Include(savedPost => savedPost.Post)
                .ThenInclude(post => post.Group)
            .Include(savedPost => savedPost.Post)
                .ThenInclude(post => post.Comments.Where(comment => !comment.IsDeleted))
                    .ThenInclude(comment => comment.User)
            .Include(savedPost => savedPost.Post)
                .ThenInclude(post => post.Reactions)
            .Where(savedPost => savedPost.Post.GroupId == null || joinedGroupIds.Contains(savedPost.Post.GroupId!.Value))
            .OrderByDescending(savedPost => savedPost.CreatedDate)
            .ToListAsync();
    }

    public async Task<Post?> GetPostWithDetailsAsync(Guid postId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        return await BuildPostDetailsQuery(dbContext).FirstOrDefaultAsync(post => post.Id == postId);
    }

    public async Task<Post?> GetPostSummaryAsync(Guid postId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        return await dbContext.Posts
            .AsNoTracking()
            .FirstOrDefaultAsync(post => post.Id == postId);
    }

    public async Task<bool> IsPostSavedByUserAsync(string currentUserId, Guid postId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        return await dbContext.SavedPosts
            .AsNoTracking()
            .AnyAsync(savedPost => savedPost.UserId == currentUserId && savedPost.PostId == postId);
    }

    public async Task AddPostAsync(Post post)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        dbContext.Posts.Add(post);
        await dbContext.SaveChangesAsync();
    }

    public async Task<bool> UpdatePostAsync(Guid postId, string content, string? mediaUrl, MediaType mediaType, DateTime updatedDate)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        var post = await dbContext.Posts.FirstOrDefaultAsync(item => item.Id == postId);
        if (post is null)
        {
            return false;
        }

        post.Content = content;
        post.MediaUrl = mediaUrl;
        post.MediaType = mediaType;
        post.UpdatedDate = updatedDate;
        await dbContext.SaveChangesAsync();
        return true;
    }

    public async Task<bool> SoftDeletePostAsync(Guid postId, DateTime updatedDate)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        var post = await dbContext.Posts.FirstOrDefaultAsync(item => item.Id == postId);
        if (post is null)
        {
            return false;
        }

        post.IsDeleted = true;
        post.UpdatedDate = updatedDate;
        await dbContext.SaveChangesAsync();
        return true;
    }

    public async Task AddCommentAsync(Comment comment)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        dbContext.Comments.Add(comment);
        await dbContext.SaveChangesAsync();
    }

    public async Task<Comment?> GetCommentWithUserAsync(Guid commentId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        return await dbContext.Comments
            .AsNoTracking()
            .Include(comment => comment.User)
            .FirstOrDefaultAsync(comment => comment.Id == commentId);
    }

    public async Task<bool> UpdateCommentAsync(Guid commentId, string content, DateTime updatedDate)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        var comment = await dbContext.Comments.FirstOrDefaultAsync(item => item.Id == commentId);
        if (comment is null)
        {
            return false;
        }

        comment.Content = content;
        comment.UpdatedDate = updatedDate;
        await dbContext.SaveChangesAsync();
        return true;
    }

    public async Task<bool> SoftDeleteCommentAsync(Guid commentId, DateTime updatedDate)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        var comment = await dbContext.Comments.FirstOrDefaultAsync(item => item.Id == commentId);
        if (comment is null)
        {
            return false;
        }

        comment.IsDeleted = true;
        comment.UpdatedDate = updatedDate;
        await dbContext.SaveChangesAsync();
        return true;
    }

    public async Task<ApplicationUser> GetRequiredUserAsync(string userId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        return await dbContext.Users.FirstAsync(user => user.Id == userId);
    }

    public async Task SetReactionAsync(Guid postId, string userId, ReactionType? reactionType)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        var reaction = await dbContext.Reactions.FirstOrDefaultAsync(item => item.PostId == postId && item.UserId == userId);

        if (!reactionType.HasValue)
        {
            if (reaction is not null)
            {
                dbContext.Reactions.Remove(reaction);
                await dbContext.SaveChangesAsync();
            }

            return;
        }

        if (reaction is null)
        {
            dbContext.Reactions.Add(new Reaction
            {
                PostId = postId,
                UserId = userId,
                Type = reactionType.Value
            });
        }
        else
        {
            reaction.Type = reactionType.Value;
        }

        await dbContext.SaveChangesAsync();
    }

    public async Task ToggleSavedPostAsync(string currentUserId, Guid postId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();
        var savedPost = await dbContext.SavedPosts
            .FirstOrDefaultAsync(item => item.UserId == currentUserId && item.PostId == postId);

        if (savedPost is null)
        {
            dbContext.SavedPosts.Add(new SavedPost
            {
                UserId = currentUserId,
                PostId = postId
            });
        }
        else
        {
            dbContext.SavedPosts.Remove(savedPost);
        }

        await dbContext.SaveChangesAsync();
    }

    private static IQueryable<Post> BuildPostDetailsQuery(ApplicationDbContext dbContext) =>
        dbContext.Posts
            .AsNoTracking()
            .Include(post => post.User)
            .Include(post => post.Group)
            .Include(post => post.Comments.Where(comment => !comment.IsDeleted))
                .ThenInclude(comment => comment.User)
            .Include(post => post.Reactions);
}
