using Microsoft.EntityFrameworkCore;
using SocialNetwork.BLL.Contracts;
using SocialNetwork.BLL.Interfaces;
using SocialNetwork.DAL;
using SocialNetwork.DAL.Entities;
using SocialNetwork.DAL.Enums;

namespace SocialNetwork.BLL.Services;

public class PostService(IDbContextFactory<ApplicationDbContext> dbContextFactory) : IPostService
{
    public async Task<IReadOnlyList<PostFeedItemDto>> GetFeedAsync(string currentUserId, Guid? groupId = null)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        if (groupId.HasValue)
        {
            var isMember = await dbContext.GroupMembers.AnyAsync(member => member.GroupId == groupId && member.UserId == currentUserId);
            if (!isMember)
            {
                throw new InvalidOperationException("Bạn phải tham gia nhóm trước khi xem bảng tin của nhóm.");
            }
        }

        var joinedGroupIds = groupId.HasValue
            ? []
            : await dbContext.GroupMembers
                .AsNoTracking()
                .Where(member => member.UserId == currentUserId)
                .Select(member => member.GroupId)
                .ToListAsync();

        var posts = await dbContext.Posts
            .AsNoTracking()
            .Include(post => post.User)
            .Include(post => post.Group)
            .Include(post => post.Comments.Where(comment => !comment.IsDeleted))
                .ThenInclude(comment => comment.User)
            .Include(post => post.Reactions)
            .Where(post => groupId.HasValue
                ? post.GroupId == groupId
                : post.GroupId == null || (post.GroupId.HasValue && joinedGroupIds.Contains(post.GroupId.Value)))
            .OrderByDescending(post => post.CreatedDate)
            .ToListAsync();

        var savedPostIds = await dbContext.SavedPosts
            .AsNoTracking()
            .Where(savedPost => savedPost.UserId == currentUserId)
            .Select(savedPost => savedPost.PostId)
            .ToListAsync();

        return posts.Select(post => MapPost(post, currentUserId, savedPostIds.Contains(post.Id))).ToList();
    }

    public async Task<IReadOnlyList<PostFeedItemDto>> GetSavedPostsAsync(string currentUserId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        var joinedGroupIds = await dbContext.GroupMembers
            .AsNoTracking()
            .Where(member => member.UserId == currentUserId)
            .Select(member => member.GroupId)
            .ToListAsync();

        var savedPosts = await dbContext.SavedPosts
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
            .Where(savedPost => savedPost.Post.GroupId == null || joinedGroupIds.Contains(savedPost.Post.GroupId.Value))
            .OrderByDescending(savedPost => savedPost.CreatedDate)
            .ToListAsync();

        return savedPosts
            .Select(savedPost => MapPost(savedPost.Post, currentUserId, true))
            .ToList();
    }

    public async Task<PostFeedItemDto?> GetPostAsync(Guid postId, string currentUserId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        var post = await dbContext.Posts
            .AsNoTracking()
            .Include(item => item.User)
            .Include(item => item.Group)
            .Include(item => item.Comments.Where(comment => !comment.IsDeleted))
                .ThenInclude(comment => comment.User)
            .Include(item => item.Reactions)
            .FirstOrDefaultAsync(item => item.Id == postId);

        if (post is null)
        {
            return null;
        }

        if (post.GroupId.HasValue)
        {
            var isMember = await dbContext.GroupMembers.AnyAsync(member => member.GroupId == post.GroupId && member.UserId == currentUserId);
            if (!isMember)
            {
                throw new InvalidOperationException("Bạn phải tham gia nhóm trước khi xem bài viết này.");
            }
        }

        var isSaved = await dbContext.SavedPosts
            .AsNoTracking()
            .AnyAsync(savedPost => savedPost.UserId == currentUserId && savedPost.PostId == post.Id);

        return MapPost(post, currentUserId, isSaved);
    }

    public async Task<PostFeedItemDto> CreatePostAsync(string currentUserId, CreatePostRequest request)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        ValidatePostContent(request.Content, request.MediaUrl, request.MediaType);

        if (request.GroupId.HasValue)
        {
            var isMember = await dbContext.GroupMembers.AnyAsync(member => member.GroupId == request.GroupId && member.UserId == currentUserId);
            if (!isMember)
            {
                throw new InvalidOperationException("Bạn phải tham gia nhóm trước khi đăng bài trong nhóm.");
            }
        }

        var post = new Post
        {
            UserId = currentUserId,
            GroupId = request.GroupId,
            Content = request.Content.Trim(),
            MediaUrl = NormalizeOptional(request.MediaUrl),
            MediaType = request.MediaType
        };

        dbContext.Posts.Add(post);
        await dbContext.SaveChangesAsync();

        return (await GetPostAsync(post.Id, currentUserId))!;
    }

    public async Task<PostFeedItemDto> UpdatePostAsync(string currentUserId, Guid postId, UpdatePostRequest request)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        ValidatePostContent(request.Content, request.MediaUrl, request.MediaType);

        var post = await dbContext.Posts.FirstOrDefaultAsync(item => item.Id == postId)
            ?? throw new InvalidOperationException("Không tìm thấy bài viết.");

        if (post.UserId != currentUserId)
        {
            throw new InvalidOperationException("Chỉ chủ bài viết mới được chỉnh sửa.");
        }

        post.Content = request.Content.Trim();
        post.MediaUrl = NormalizeOptional(request.MediaUrl);
        post.MediaType = request.MediaType;
        post.UpdatedDate = DateTime.UtcNow;

        await dbContext.SaveChangesAsync();

        return (await GetPostAsync(post.Id, currentUserId))!;
    }

    public async Task DeletePostAsync(string currentUserId, Guid postId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        var post = await dbContext.Posts.FirstOrDefaultAsync(item => item.Id == postId)
            ?? throw new InvalidOperationException("Không tìm thấy bài viết.");

        if (post.UserId != currentUserId)
        {
            throw new InvalidOperationException("Chỉ chủ bài viết mới được xóa.");
        }

        post.IsDeleted = true;
        post.UpdatedDate = DateTime.UtcNow;
        await dbContext.SaveChangesAsync();
    }

    public async Task<CommentDto> AddCommentAsync(string currentUserId, CreateCommentRequest request)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        if (string.IsNullOrWhiteSpace(request.Content))
        {
            throw new InvalidOperationException("Nội dung bình luận là bắt buộc.");
        }

        var post = await dbContext.Posts.FirstOrDefaultAsync(item => item.Id == request.PostId)
            ?? throw new InvalidOperationException("Không tìm thấy bài viết.");

        if (post.GroupId.HasValue)
        {
            var isMember = await dbContext.GroupMembers.AnyAsync(member => member.GroupId == post.GroupId && member.UserId == currentUserId);
            if (!isMember)
            {
                throw new InvalidOperationException("Bạn phải tham gia nhóm trước khi bình luận.");
            }
        }

        var comment = new Comment
        {
            PostId = post.Id,
            UserId = currentUserId,
            Content = request.Content.Trim()
        };

        dbContext.Comments.Add(comment);
        await dbContext.SaveChangesAsync();

        var author = await dbContext.Users.FirstAsync(user => user.Id == currentUserId);
        return MapComment(comment, author, currentUserId);
    }

    public async Task<CommentDto> UpdateCommentAsync(string currentUserId, Guid commentId, string content)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        if (string.IsNullOrWhiteSpace(content))
        {
            throw new InvalidOperationException("Nội dung bình luận là bắt buộc.");
        }

        var comment = await dbContext.Comments.Include(item => item.User).FirstOrDefaultAsync(item => item.Id == commentId)
            ?? throw new InvalidOperationException("Không tìm thấy bình luận.");

        if (comment.UserId != currentUserId)
        {
            throw new InvalidOperationException("Chỉ chủ bình luận mới được chỉnh sửa.");
        }

        comment.Content = content.Trim();
        comment.UpdatedDate = DateTime.UtcNow;
        await dbContext.SaveChangesAsync();

        return MapComment(comment, comment.User, currentUserId);
    }

    public async Task DeleteCommentAsync(string currentUserId, Guid commentId)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        var comment = await dbContext.Comments.FirstOrDefaultAsync(item => item.Id == commentId)
            ?? throw new InvalidOperationException("Không tìm thấy bình luận.");

        if (comment.UserId != currentUserId)
        {
            throw new InvalidOperationException("Chỉ chủ bình luận mới được xóa.");
        }

        comment.IsDeleted = true;
        comment.UpdatedDate = DateTime.UtcNow;
        await dbContext.SaveChangesAsync();
    }

    public async Task SetReactionAsync(string currentUserId, Guid postId, ReactionType? reactionType)
    {
        await using var dbContext = await dbContextFactory.CreateDbContextAsync();

        var post = await dbContext.Posts.FirstOrDefaultAsync(item => item.Id == postId)
            ?? throw new InvalidOperationException("Không tìm thấy bài viết.");

        if (post.GroupId.HasValue)
        {
            var isMember = await dbContext.GroupMembers.AnyAsync(member => member.GroupId == post.GroupId && member.UserId == currentUserId);
            if (!isMember)
            {
                throw new InvalidOperationException("Bạn phải tham gia nhóm trước khi tương tác.");
            }
        }

        var reaction = await dbContext.Reactions.FirstOrDefaultAsync(item => item.PostId == postId && item.UserId == currentUserId);

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
                UserId = currentUserId,
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

        var post = await dbContext.Posts.FirstOrDefaultAsync(item => item.Id == postId)
            ?? throw new InvalidOperationException("Không tìm thấy bài viết.");

        if (post.GroupId.HasValue)
        {
            var isMember = await dbContext.GroupMembers.AnyAsync(member => member.GroupId == post.GroupId && member.UserId == currentUserId);
            if (!isMember)
            {
                throw new InvalidOperationException("Bạn phải tham gia nhóm trước khi lưu bài viết.");
            }
        }

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

    private static void ValidatePostContent(string content, string? mediaUrl, MediaType mediaType)
    {
        if (string.IsNullOrWhiteSpace(content) && string.IsNullOrWhiteSpace(mediaUrl))
        {
            throw new InvalidOperationException("Bài viết phải có nội dung hoặc media.");
        }

        if (mediaType != MediaType.Text && string.IsNullOrWhiteSpace(mediaUrl))
        {
            throw new InvalidOperationException("Cần nhập liên kết media cho bài viết ảnh hoặc video.");
        }
    }

    private static string? NormalizeOptional(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static PostFeedItemDto MapPost(Post post, string currentUserId, bool isSaved)
    {
        var comments = post.Comments
            .OrderBy(comment => comment.CreatedDate)
            .Select(comment => MapComment(comment, comment.User, currentUserId))
            .ToList();

        var reactions = post.Reactions
            .GroupBy(reaction => reaction.Type)
            .Select(group => new ReactionCountDto(group.Key, group.Count()))
            .OrderBy(item => item.Type)
            .ToList();

        return new PostFeedItemDto(
            post.Id,
            post.UserId,
            string.IsNullOrWhiteSpace(post.User.DisplayName) ? post.User.Email ?? post.User.UserName ?? "Người dùng" : post.User.DisplayName,
            post.User.AvatarUrl,
            post.Content,
            post.MediaUrl,
            post.MediaType,
            post.CreatedDate,
            post.UpdatedDate,
            post.UserId == currentUserId,
            post.GroupId,
            post.Group?.Name,
            comments,
            reactions,
            post.Reactions.FirstOrDefault(reaction => reaction.UserId == currentUserId)?.Type,
            comments.Count,
            isSaved);
    }

    private static CommentDto MapComment(Comment comment, ApplicationUser author, string currentUserId) =>
        new(
            comment.Id,
            comment.UserId,
            string.IsNullOrWhiteSpace(author.DisplayName) ? author.Email ?? author.UserName ?? "Người dùng" : author.DisplayName,
            author.AvatarUrl,
            comment.Content,
            comment.CreatedDate,
            comment.UpdatedDate,
            comment.UserId == currentUserId);
}
