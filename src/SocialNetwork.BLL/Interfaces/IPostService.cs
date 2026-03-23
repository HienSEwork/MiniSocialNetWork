using SocialNetwork.BLL.Contracts;
using SocialNetwork.DAL.Enums;

namespace SocialNetwork.BLL.Interfaces;

public interface IPostService
{
    Task<IReadOnlyList<PostFeedItemDto>> GetFeedAsync(string currentUserId, Guid? groupId = null);

    Task<IReadOnlyList<PostFeedItemDto>> GetSavedPostsAsync(string currentUserId);

    Task<PostFeedItemDto?> GetPostAsync(Guid postId, string currentUserId);

    Task<PostFeedItemDto> CreatePostAsync(string currentUserId, CreatePostRequest request);

    Task<PostFeedItemDto> UpdatePostAsync(string currentUserId, Guid postId, UpdatePostRequest request);

    Task DeletePostAsync(string currentUserId, Guid postId);

    Task<CommentDto> AddCommentAsync(string currentUserId, CreateCommentRequest request);

    Task<CommentDto> UpdateCommentAsync(string currentUserId, Guid commentId, string content);

    Task DeleteCommentAsync(string currentUserId, Guid commentId);

    Task SetReactionAsync(string currentUserId, Guid postId, ReactionType? reactionType);

    Task ToggleSavedPostAsync(string currentUserId, Guid postId);
}
