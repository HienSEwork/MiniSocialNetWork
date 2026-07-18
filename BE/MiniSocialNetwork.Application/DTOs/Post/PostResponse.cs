namespace MiniSocialNetwork.Application.DTOs.Post;

public class PostResponse
{
    public Guid Id { get; set; }
    public Guid? GroupId { get; set; }

    public string UserId { get; set; } = string.Empty;

    public string Content { get; set; } = string.Empty;
    public string? MediaUrl { get; set; }
    public int MediaType { get; set; }

    public DateTime CreatedDate { get; set; }
    public DateTime? UpdatedDate { get; set; }

    public int CommentCount { get; set; }
    public int ReactionCount { get; set; }
}
