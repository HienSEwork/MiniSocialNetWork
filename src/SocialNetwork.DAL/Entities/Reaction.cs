using SocialNetwork.DAL.Enums;

namespace SocialNetwork.DAL.Entities;

public class Reaction
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid PostId { get; set; }

    public string UserId { get; set; } = string.Empty;

    public ReactionType Type { get; set; }

    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;

    public Post Post { get; set; } = null!;

    public ApplicationUser User { get; set; } = null!;
}
