using SocialNetwork.BLL.Contracts;
using SocialNetwork.BLL.Interfaces;
using SocialNetwork.DAL.Entities;
using SocialNetwork.DAL.Enums;
using SocialNetwork.DAL.Repositories;

namespace SocialNetwork.BLL.Services;

public class PostService(IPostRepository postRepository) : IPostService
{
    public async Task<IReadOnlyList<PostFeedItemDto>> GetFeedAsync(string currentUserId, Guid? groupId = null)
    {
        if (groupId.HasValue && !await postRepository.IsUserMemberOfGroupAsync(currentUserId, groupId.Value))
        {
            throw new InvalidOperationException("Bạn phải tham gia nhóm trước khi xem bảng tin của nhóm.");
        }

        var posts = await postRepository.GetFeedPostsAsync(currentUserId, groupId);
        var savedPostIds = await postRepository.GetSavedPostIdsAsync(currentUserId);
        var savedLookup = savedPostIds.ToHashSet();

        return posts
            .Select(post => MapPost(post, currentUserId, savedLookup.Contains(post.Id)))
            .ToList();
    }

    public async Task<IReadOnlyList<PostFeedItemDto>> GetSavedPostsAsync(string currentUserId)
    {
        var savedPosts = await postRepository.GetSavedPostsAsync(currentUserId);

        return savedPosts
            .Select(savedPost => MapPost(savedPost.Post, currentUserId, true))
            .ToList();
    }

    public async Task<PostFeedItemDto?> GetPostAsync(Guid postId, string currentUserId)
    {
        var post = await postRepository.GetPostWithDetailsAsync(postId);
        if (post is null)
        {
            return null;
        }

        if (post.GroupId.HasValue && !await postRepository.IsUserMemberOfGroupAsync(currentUserId, post.GroupId.Value))
        {
            throw new InvalidOperationException("Bạn phải tham gia nhóm trước khi xem bài viết này.");
        }

        var isSaved = await postRepository.IsPostSavedByUserAsync(currentUserId, post.Id);
        return MapPost(post, currentUserId, isSaved);
    }

    public async Task<PostFeedItemDto> CreatePostAsync(string currentUserId, CreatePostRequest request)
    {
        ValidatePostContent(request.Content, request.MediaUrl, request.MediaType);

        if (request.GroupId.HasValue && !await postRepository.IsUserMemberOfGroupAsync(currentUserId, request.GroupId.Value))
        {
            throw new InvalidOperationException("Bạn phải tham gia nhóm trước khi đăng bài trong nhóm.");
        }

        var post = new Post
        {
            UserId = currentUserId,
            GroupId = request.GroupId,
            Content = request.Content.Trim(),
            MediaUrl = NormalizeOptional(request.MediaUrl),
            MediaType = request.MediaType
        };

        await postRepository.AddPostAsync(post);

        return (await GetPostAsync(post.Id, currentUserId))!;
    }

    public async Task<PostFeedItemDto> UpdatePostAsync(string currentUserId, Guid postId, UpdatePostRequest request)
    {
        ValidatePostContent(request.Content, request.MediaUrl, request.MediaType);

        var post = await postRepository.GetPostSummaryAsync(postId)
            ?? throw new InvalidOperationException("Không tìm thấy bài viết.");

        if (post.UserId != currentUserId)
        {
            throw new InvalidOperationException("Chỉ chủ bài viết mới được chỉnh sửa.");
        }

        await postRepository.UpdatePostAsync(
            postId,
            request.Content.Trim(),
            NormalizeOptional(request.MediaUrl),
            request.MediaType,
            DateTime.UtcNow);

        return (await GetPostAsync(post.Id, currentUserId))!;
    }

    public async Task DeletePostAsync(string currentUserId, Guid postId)
    {
        var post = await postRepository.GetPostSummaryAsync(postId)
            ?? throw new InvalidOperationException("Không tìm thấy bài viết.");

        if (post.UserId != currentUserId)
        {
            throw new InvalidOperationException("Chỉ chủ bài viết mới được xóa.");
        }

        await postRepository.SoftDeletePostAsync(postId, DateTime.UtcNow);
    }

    public async Task<CommentDto> AddCommentAsync(string currentUserId, CreateCommentRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Content))
        {
            throw new InvalidOperationException("Nội dung bình luận là bắt buộc.");
        }

        var post = await postRepository.GetPostSummaryAsync(request.PostId)
            ?? throw new InvalidOperationException("Không tìm thấy bài viết.");

        if (post.GroupId.HasValue && !await postRepository.IsUserMemberOfGroupAsync(currentUserId, post.GroupId.Value))
        {
            throw new InvalidOperationException("Bạn phải tham gia nhóm trước khi bình luận.");
        }

        var comment = new Comment
        {
            PostId = post.Id,
            UserId = currentUserId,
            Content = request.Content.Trim()
        };

        await postRepository.AddCommentAsync(comment);

        var author = await postRepository.GetRequiredUserAsync(currentUserId);
        return MapComment(comment, author, currentUserId);
    }

    public async Task<CommentDto> UpdateCommentAsync(string currentUserId, Guid commentId, string content)
    {
        if (string.IsNullOrWhiteSpace(content))
        {
            throw new InvalidOperationException("Nội dung bình luận là bắt buộc.");
        }

        var comment = await postRepository.GetCommentWithUserAsync(commentId)
            ?? throw new InvalidOperationException("Không tìm thấy bình luận.");

        if (comment.UserId != currentUserId)
        {
            throw new InvalidOperationException("Chỉ chủ bình luận mới được chỉnh sửa.");
        }

        var updatedContent = content.Trim();
        var updatedDate = DateTime.UtcNow;
        await postRepository.UpdateCommentAsync(commentId, updatedContent, updatedDate);

        comment.Content = updatedContent;
        comment.UpdatedDate = updatedDate;
        return MapComment(comment, comment.User, currentUserId);
    }

    public async Task DeleteCommentAsync(string currentUserId, Guid commentId)
    {
        var comment = await postRepository.GetCommentWithUserAsync(commentId)
            ?? throw new InvalidOperationException("Không tìm thấy bình luận.");

        if (comment.UserId != currentUserId)
        {
            throw new InvalidOperationException("Chỉ chủ bình luận mới được xóa.");
        }

        await postRepository.SoftDeleteCommentAsync(commentId, DateTime.UtcNow);
    }

    public async Task SetReactionAsync(string currentUserId, Guid postId, ReactionType? reactionType)
    {
        var post = await postRepository.GetPostSummaryAsync(postId)
            ?? throw new InvalidOperationException("Không tìm thấy bài viết.");

        if (post.GroupId.HasValue && !await postRepository.IsUserMemberOfGroupAsync(currentUserId, post.GroupId.Value))
        {
            throw new InvalidOperationException("Bạn phải tham gia nhóm trước khi tương tác.");
        }

        await postRepository.SetReactionAsync(postId, currentUserId, reactionType);
    }

    public async Task ToggleSavedPostAsync(string currentUserId, Guid postId)
    {
        var post = await postRepository.GetPostSummaryAsync(postId)
            ?? throw new InvalidOperationException("Không tìm thấy bài viết.");

        if (post.GroupId.HasValue && !await postRepository.IsUserMemberOfGroupAsync(currentUserId, post.GroupId.Value))
        {
            throw new InvalidOperationException("Bạn phải tham gia nhóm trước khi lưu bài viết.");
        }

        await postRepository.ToggleSavedPostAsync(currentUserId, postId);
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
