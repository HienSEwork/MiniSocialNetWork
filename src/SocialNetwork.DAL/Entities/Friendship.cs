namespace SocialNetwork.DAL.Entities;

public class Friendship
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public string RequesterId { get; set; } = string.Empty;

    public string AddresseeId { get; set; } = string.Empty;

    public DateTime CreatedDate { get; set; } = DateTime.UtcNow;

    public ApplicationUser Requester { get; set; } = null!;

    public ApplicationUser Addressee { get; set; } = null!;
}
