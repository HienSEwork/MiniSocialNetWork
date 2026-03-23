namespace SocialNetwork.DAL.Entities;

public class Message
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public string SenderId { get; set; } = string.Empty;

    public string? ReceiverId { get; set; }

    public Guid? GroupId { get; set; }

    public string Content { get; set; } = string.Empty;

    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;

    public bool IsGroupMessage { get; set; }

    public ApplicationUser Sender { get; set; } = null!;

    public ApplicationUser? Receiver { get; set; }

    public Group? Group { get; set; }
}
