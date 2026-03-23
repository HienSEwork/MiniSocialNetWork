using SocialNetwork.DAL.Enums;

namespace SocialNetwork.DAL.Entities;

public class Post
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public string UserId { get; set; } = string.Empty;

    public Guid? GroupId { get; set; }

    public string Content { get; set; } = string.Empty;

    public string? MediaUrl { get; set; }

    public MediaType MediaType { get; set; } = MediaType.Text;

    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;

    public DateTime? UpdatedDate { get; set; }

    public bool IsDeleted { get; set; }

    public ApplicationUser User { get; set; } = null!;

    public Group? Group { get; set; }

    public ICollection<Comment> Comments { get; set; } = new List<Comment>();

    public ICollection<Reaction> Reactions { get; set; } = new List<Reaction>();

    public ICollection<SavedPost> SavedPosts { get; set; } = new List<SavedPost>();
}
