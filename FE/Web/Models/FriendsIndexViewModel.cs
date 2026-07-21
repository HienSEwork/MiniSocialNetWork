namespace MiniSocialNetwork.Web.Models;

public sealed class FriendsIndexViewModel
{
    public List<FriendDto> Friends { get; set; } = new();
    public List<FriendSearchDto> SearchResults { get; set; } = new();
}