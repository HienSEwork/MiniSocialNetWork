namespace MiniSocialNetwork.Domain.Entities;

public class GroupMember
{
    public Guid GroupId { get; set; }
    public Group Group { get; set; } = null!;
    public string UserId { get; set; } = string.Empty;
    public AppUser User { get; set; } = null!;
    public int Role { get; set; }
    public DateTime JoinedDate { get; set; }
}
