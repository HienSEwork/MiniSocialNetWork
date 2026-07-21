namespace MiniSocialNetwork.Application.DTOs.Chat;

public sealed class SendMessageRequest
{
    public string? ReceiverId { get; set; }
    public Guid? GroupId { get; set; }
    public string Content { get; set; } = string.Empty;
}

public sealed class MessageResponse
{
    public Guid Id { get; set; }
    public string SenderId { get; set; } = string.Empty;
    public string SenderName { get; set; } = string.Empty;
    public string? SenderAvatarUrl { get; set; }
    public string? ReceiverId { get; set; }
    public Guid? GroupId { get; set; }
    public string Content { get; set; } = string.Empty;
    public DateTime CreatedDate { get; set; }
    public bool IsGroupMessage { get; set; }
}

public sealed class ChatUserResponse
{
    public string Id { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public string? Bio { get; set; }
}
