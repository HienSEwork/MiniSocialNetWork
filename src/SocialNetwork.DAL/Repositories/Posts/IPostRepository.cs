using SocialNetwork.DAL.Entities;
using SocialNetwork.DAL.Enums;

namespace SocialNetwork.DAL.Repositories;

public interface IPostRepository
{
    Task<bool> IsUserMemberOfGroupAsync(string userId, Guid groupId);

    Task<IReadOnlyList<Post>> GetFeedPostsAsync(string currentUserId, Guid? groupId = null);

    Task<IReadOnlyCollection<Guid>> GetSavedPostIdsAsync(string currentUserId);

    Task<IReadOnlyList<SavedPost>> GetSavedPostsAsync(string currentUserId);

    Task<Post?> GetPostWithDetailsAsync(Guid postId);

    Task<Post?> GetPostSummaryAsync(Guid postId);

    Task<bool> IsPostSavedByUserAsync(string currentUserId, Guid postId);

    Task AddPostAsync(Post post);

    Task<bool> UpdatePostAsync(Guid postId, string content, string? mediaUrl, MediaType mediaType, DateTime updatedDate);

    Task<bool> SoftDeletePostAsync(Guid postId, DateTime updatedDate);

    Task AddCommentAsync(Comment comment);

    Task<Comment?> GetCommentWithUserAsync(Guid commentId);

    Task<bool> UpdateCommentAsync(Guid commentId, string content, DateTime updatedDate);

    Task<bool> SoftDeleteCommentAsync(Guid commentId, DateTime updatedDate);

    Task<ApplicationUser> GetRequiredUserAsync(string userId);

    Task SetReactionAsync(Guid postId, string userId, ReactionType? reactionType);

    Task ToggleSavedPostAsync(string currentUserId, Guid postId);
}
