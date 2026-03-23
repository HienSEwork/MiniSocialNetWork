namespace SocialNetwork.DAL.Entities;

public class Group
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public string Name { get; set; } = string.Empty;

    public string Description { get; set; } = string.Empty;

    public string OwnerId { get; set; } = string.Empty;

    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;

    public bool IsDeleted { get; set; }

    public ApplicationUser Owner { get; set; } = null!;

    public ICollection<GroupMember> Members { get; set; } = new List<GroupMember>();

    public ICollection<Message> Messages { get; set; } = new List<Message>();

    public ICollection<Post> Posts { get; set; } = new List<Post>();
}
