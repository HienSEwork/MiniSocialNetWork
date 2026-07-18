namespace MiniSocialNetwork.Domain.Entities;

public class Comment
{
    public Guid Id { get; set; }

    public Guid PostId { get; set; }
    public Post Post { get; set; }

    public string UserId { get; set; }
    public AppUser User { get; set; }

    public string Content { get; set; }

    public DateTime CreatedDate { get; set; }
    public DateTime? UpdatedDate { get; set; }
    public bool IsDeleted { get; set; }
}