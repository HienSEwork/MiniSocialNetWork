using Microsoft.AspNetCore.Identity;

namespace SocialNetwork.DAL.Entities;

public class ApplicationUser : IdentityUser
{
    public string DisplayName { get; set; } = string.Empty;

    public string? AvatarUrl { get; set; }

    public string? Bio { get; set; }

    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;

    public ICollection<Post> Posts { get; set; } = new List<Post>();

    public ICollection<Comment> Comments { get; set; } = new List<Comment>();

    public ICollection<Reaction> Reactions { get; set; } = new List<Reaction>();

    public ICollection<SavedPost> SavedPosts { get; set; } = new List<SavedPost>();

    public ICollection<Message> SentMessages { get; set; } = new List<Message>();

    public ICollection<Message> ReceivedMessages { get; set; } = new List<Message>();

    public ICollection<Group> OwnedGroups { get; set; } = new List<Group>();

    public ICollection<GroupMember> GroupMemberships { get; set; } = new List<GroupMember>();

    public ICollection<Friendship> FriendshipsRequested { get; set; } = new List<Friendship>();

    public ICollection<Friendship> FriendshipsReceived { get; set; } = new List<Friendship>();

    public ICollection<Notification> Notifications { get; set; } = new List<Notification>();

    public ICollection<Notification> NotificationsCreated { get; set; } = new List<Notification>();
}
