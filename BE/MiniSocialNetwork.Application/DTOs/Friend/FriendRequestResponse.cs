using System;

namespace MiniSocialNetwork.Application.DTOs.Friend;

public class FriendRequestResponse
{
    public Guid Id { get; set; }
    public string RequesterId { get; set; } = string.Empty;
    public string RequesterName { get; set; } = string.Empty;
    public string? RequesterAvatarUrl { get; set; }
    public DateTime CreatedDate { get; set; }
}
