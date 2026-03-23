namespace SocialNetwork.DAL.Entities;

public class SavedPost
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public string UserId { get; set; } = string.Empty;

    public Guid PostId { get; set; }

    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;

    public ApplicationUser User { get; set; } = null!;

    public Post Post { get; set; } = null!;
}
