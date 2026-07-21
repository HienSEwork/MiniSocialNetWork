namespace MiniSocialNetwork.Domain.Entities;

public class Reaction
{
    public Guid Id { get; set; }
    public Guid PostId { get; set; }
    public Post Post { get; set; } = null!;
    public string UserId { get; set; } = string.Empty;
    public AppUser User { get; set; } = null!;
    public int Type { get; set; }
    public DateTime CreatedDate { get; set; }
}
