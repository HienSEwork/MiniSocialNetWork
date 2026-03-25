namespace SocialNetwork.BLL.Contracts;

public sealed record FriendSummaryDto(
    string UserId,
    string DisplayName,
    string Email,
    string? AvatarUrl,
    string? Bio,
    bool IsFriend,
    bool HasSentRequest,
    bool HasReceivedRequest)
{
    public bool HasPendingRequest => HasSentRequest || HasReceivedRequest;
}
