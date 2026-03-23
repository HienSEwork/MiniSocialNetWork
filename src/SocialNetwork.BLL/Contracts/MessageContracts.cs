namespace SocialNetwork.BLL.Contracts;

public sealed record MessageDto(
    Guid Id,
    string SenderId,
    string SenderName,
    string? SenderAvatarUrl,
    string? ReceiverId,
    Guid? GroupId,
    string Content,
    DateTime CreatedDate,
    bool IsMine,
    bool IsGroupMessage);
