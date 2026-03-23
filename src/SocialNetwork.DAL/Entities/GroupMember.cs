using SocialNetwork.DAL.Enums;

namespace SocialNetwork.DAL.Entities;

public class GroupMember
{
    public Guid GroupId { get; set; }

    public string UserId { get; set; } = string.Empty;

    public GroupRole Role { get; set; } = GroupRole.Member;

    public DateTime JoinedDate { get; set; } = DateTime.UtcNow;

    public Group Group { get; set; } = null!;

    public ApplicationUser User { get; set; } = null!;
}
