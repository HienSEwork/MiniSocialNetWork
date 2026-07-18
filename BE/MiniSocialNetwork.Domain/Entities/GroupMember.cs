namespace MiniSocialNetwork.Domain.Entities;

public class GroupMember
{
    public Guid GroupId { get; set; }
    public string UserId { get; set; }
    public int Role { get; set; }
    public DateTime JoinedDate { get; set; }

    public Group Group { get; set; }
}