namespace MiniSocialNetwork.Web.Models;

public sealed class FriendDto
{
    public string Id { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public int RelationshipStatus { get; set; } // 1 = friends
}