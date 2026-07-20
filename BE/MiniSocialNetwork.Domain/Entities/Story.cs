namespace MiniSocialNetwork.Domain.Entities;

public class Story
{
    public Guid Id { get; set; }
    public string UserId { get; set; } = string.Empty;
    public AppUser User { get; set; } = null!;
    public string Content { get; set; } = string.Empty;
    public string? MediaUrl { get; set; }
    public int MediaType { get; set; }
    public DateTime CreatedDate { get; set; }
    public DateTime ExpiresAt { get; set; }
    public DateTime? UpdatedDate { get; set; }
    public bool IsDeleted { get; set; }
}
