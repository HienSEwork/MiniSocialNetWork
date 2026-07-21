namespace MiniSocialNetwork.Domain.Entities;

public class StoryReaction
{
    public Guid Id { get; set; }
    public Guid StoryId { get; set; }
    public Story Story { get; set; } = null!;
    public string UserId { get; set; } = string.Empty;
    public AppUser User { get; set; } = null!;
    public int Type { get; set; }
    public DateTime CreatedDate { get; set; }
    public DateTime? UpdatedDate { get; set; }
}
