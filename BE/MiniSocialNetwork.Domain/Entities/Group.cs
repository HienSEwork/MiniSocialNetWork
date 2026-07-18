namespace MiniSocialNetwork.Domain.Entities;

public class Group
{
    public Guid Id { get; set; }
    public string Name { get; set; }
    public string Description { get; set; }

    public string OwnerId { get; set; }
    public AppUser Owner { get; set; }

    public DateTime CreatedDate { get; set; }
    public bool IsDeleted { get; set; }

    public ICollection<GroupMember> Members { get; set; }
    public ICollection<Post> Posts { get; set; }
}