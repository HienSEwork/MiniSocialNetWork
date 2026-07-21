namespace MiniSocialNetwork.Web.Models;

public sealed class FriendSearchDto
{
    public string Id { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public int RelationshipStatus { get; set; } // 0..4 mapping from API
}