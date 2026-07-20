namespace MiniSocialNetwork.Application.DTOs.Story;

public class StoryResponse
{
    public Guid Id { get; set; }
    public string UserId { get; set; } = string.Empty;
    public string AuthorName { get; set; } = string.Empty;
    public string? AuthorAvatarUrl { get; set; }
    public string Content { get; set; } = string.Empty;
    public string? MediaUrl { get; set; }
    public int MediaType { get; set; }
    public DateTime CreatedDate { get; set; }
    public DateTime ExpiresAt { get; set; }
    public DateTime? UpdatedDate { get; set; }
}

public class CreateStoryRequest
{
    public string Content { get; set; } = string.Empty;
    public string? MediaUrl { get; set; }
    public int MediaType { get; set; }
}
