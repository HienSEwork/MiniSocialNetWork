namespace SocialNetwork.DAL.Entities;

public class Comment
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid PostId { get; set; }

    public string UserId { get; set; } = string.Empty;

    public string Content { get; set; } = string.Empty;

    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;

    public DateTime? UpdatedDate { get; set; }

    public bool IsDeleted { get; set; }

    public Post Post { get; set; } = null!;

    public ApplicationUser User { get; set; } = null!;
}
