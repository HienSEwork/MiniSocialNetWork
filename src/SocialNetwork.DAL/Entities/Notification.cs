using SocialNetwork.DAL.Enums;

namespace SocialNetwork.DAL.Entities;

public class Notification
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public string UserId { get; set; } = string.Empty;

    public string ActorId { get; set; } = string.Empty;

    public NotificationType Type { get; set; }

    public string Title { get; set; } = string.Empty;

    public string Message { get; set; } = string.Empty;

    public string? Link { get; set; }

    public bool IsRead { get; set; }

    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;

    public ApplicationUser User { get; set; } = null!;

    public ApplicationUser Actor { get; set; } = null!;
}
