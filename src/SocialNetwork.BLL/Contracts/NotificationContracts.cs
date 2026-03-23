using SocialNetwork.DAL.Enums;

namespace SocialNetwork.BLL.Contracts;

public sealed record NotificationDto(
    Guid Id,
    string UserId,
    string ActorId,
    string ActorName,
    NotificationType Type,
    string Title,
    string Message,
    string? Link,
    bool IsRead,
    DateTime CreatedDate);
