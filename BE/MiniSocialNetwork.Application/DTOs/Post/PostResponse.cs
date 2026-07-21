namespace MiniSocialNetwork.Application.DTOs.Post;

public class PostResponse
{
    public Guid Id { get; set; }
    public Guid? GroupId { get; set; }

    public string UserId { get; set; } = string.Empty;
    public string AuthorName { get; set; } = string.Empty;
    public string? AuthorAvatarUrl { get; set; }
    public string? GroupName { get; set; }

    public string Content { get; set; } = string.Empty;
    public string? MediaUrl { get; set; }
    public int MediaType { get; set; }

    public DateTime CreatedDate { get; set; }
    public DateTime? UpdatedDate { get; set; }

    public int CommentCount { get; set; }
    public int ReactionCount { get; set; }
    public IReadOnlyDictionary<int, int> ReactionCounts { get; set; } = new Dictionary<int, int>();
}
