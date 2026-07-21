using System;
using MiniSocialNetwork.Domain.Enums;

namespace MiniSocialNetwork.Domain.Entities;

public class FriendRequest
{
    public Guid Id { get; set; }
    public string RequesterId { get; set; } = string.Empty;
    public AppUser Requester { get; set; } = null!;
    public string AddresseeId { get; set; } = string.Empty;
    public AppUser Addressee { get; set; } = null!;
    public FriendRequestStatus Status { get; set; }
    public DateTime CreatedDate { get; set; }
    public DateTime? RespondedDate { get; set; }
}
