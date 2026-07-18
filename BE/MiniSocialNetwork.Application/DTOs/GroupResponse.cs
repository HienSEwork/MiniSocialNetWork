namespace MiniSocialNetwork.Application.DTOs.Group;

public class GroupResponse
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string OwnerId { get; set; } = string.Empty;
    public int MemberCount { get; set; }
    public DateTime CreatedDate { get; set; }
}
