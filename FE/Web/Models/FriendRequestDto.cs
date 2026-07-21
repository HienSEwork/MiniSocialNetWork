namespace MiniSocialNetwork.Web.Models;

public sealed class FriendRequestDto
{
    public Guid Id { get; set; }
    public string RequesterId { get; set; } = string.Empty;
    public string RequesterName { get; set; } = string.Empty;
    public string? RequesterAvatarUrl { get; set; }
    public DateTime CreatedDate { get; set; }
}