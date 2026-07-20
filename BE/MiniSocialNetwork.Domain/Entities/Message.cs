namespace MiniSocialNetwork.Domain.Entities;

public class Message
{
    public Guid Id { get; set; }
    public string SenderId { get; set; } = string.Empty;
    public AppUser Sender { get; set; } = null!;
    public string? ReceiverId { get; set; }
    public AppUser? Receiver { get; set; }
    public Guid? GroupId { get; set; }
    public Group? Group { get; set; }
    public string Content { get; set; } = string.Empty;
    public DateTime CreatedDate { get; set; }
    public bool IsGroupMessage { get; set; }
}
