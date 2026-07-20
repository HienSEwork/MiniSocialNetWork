namespace MiniSocialNetwork.Domain.Entities;

public class Group
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string OwnerId { get; set; } = string.Empty;
    public AppUser Owner { get; set; } = null!;
    public DateTime CreatedDate { get; set; }
    public bool IsDeleted { get; set; }
    public ICollection<GroupMember> Members { get; set; } = new List<GroupMember>();
    public ICollection<Post> Posts { get; set; } = new List<Post>();
}
