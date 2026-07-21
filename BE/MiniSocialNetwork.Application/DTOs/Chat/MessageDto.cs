namespace MiniSocialNetwork.Application.DTOs.Chat;

public class MessageDto
{
    public Guid Id { get; set; }
    public string SenderId { get; set; } = string.Empty;
    public string? ReceiverId { get; set; }
    public Guid? GroupId { get; set; }
    public string Content { get; set; } = string.Empty;
    public DateTime CreatedDate { get; set; }
    public bool IsGroupMessage { get; set; }
}
