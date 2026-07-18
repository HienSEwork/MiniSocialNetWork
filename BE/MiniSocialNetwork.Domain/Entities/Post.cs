using System.Xml.Linq;

namespace MiniSocialNetwork.Domain.Entities;

public class Post
{
    public Guid Id { get; set; }

    public string UserId { get; set; }
    public AppUser User { get; set; }

    public Guid? GroupId { get; set; }
    public Group? Group { get; set; }

    public string Content { get; set; }
    public string? MediaUrl { get; set; }
    public int MediaType { get; set; }

    public DateTime CreatedDate { get; set; }
    public DateTime? UpdatedDate { get; set; }
    public bool IsDeleted { get; set; }

    public ICollection<Comment> Comments { get; set; }
    public ICollection<Reaction> Reactions { get; set; }
}