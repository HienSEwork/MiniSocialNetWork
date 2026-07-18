namespace MiniSocialNetwork.Domain.Entities;

public class Reaction
{
    public Guid Id { get; set; }

    public Guid PostId { get; set; }
    public Post Post { get; set; }

    public string UserId { get; set; }
    public AppUser User { get; set; }

    public int Type { get; set; }
    public DateTime CreatedDate { get; set; }
}