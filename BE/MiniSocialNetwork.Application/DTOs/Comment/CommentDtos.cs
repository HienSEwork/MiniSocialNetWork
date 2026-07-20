namespace MiniSocialNetwork.Application.DTOs.Comment;

public sealed class CommentRequest
{
    public string Content { get; set; } = string.Empty;
}

public sealed class CommentResponse
{
    public Guid Id { get; set; }
    public Guid PostId { get; set; }
    public string UserId { get; set; } = string.Empty;
    public string AuthorName { get; set; } = string.Empty;
    public string? AuthorAvatarUrl { get; set; }
    public string Content { get; set; } = string.Empty;
    public DateTime CreatedDate { get; set; }
    public DateTime? UpdatedDate { get; set; }
}
