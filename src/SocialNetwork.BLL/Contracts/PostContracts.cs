using SocialNetwork.DAL.Enums;

namespace SocialNetwork.BLL.Contracts;

public sealed record ReactionCountDto(ReactionType Type, int Count);

public sealed record CommentDto(
    Guid Id,
    string UserId,
    string AuthorName,
    string? AuthorAvatarUrl,
    string Content,
    DateTime CreatedDate,
    DateTime? UpdatedDate,
    bool CanEdit);

public sealed record PostFeedItemDto(
    Guid Id,
    string UserId,
    string AuthorName,
    string? AuthorAvatarUrl,
    string Content,
    string? MediaUrl,
    MediaType MediaType,
    DateTime CreatedDate,
    DateTime? UpdatedDate,
    bool CanEdit,
    Guid? GroupId,
    string? GroupName,
    IReadOnlyList<CommentDto> Comments,
    IReadOnlyList<ReactionCountDto> Reactions,
    ReactionType? CurrentUserReaction,
    int CommentCount,
    bool IsSaved);

public sealed record CreatePostRequest(
    string Content,
    string? MediaUrl,
    MediaType MediaType,
    Guid? GroupId);

public sealed record UpdatePostRequest(
    string Content,
    string? MediaUrl,
    MediaType MediaType);

public sealed record CreateCommentRequest(
    Guid PostId,
    string Content);
