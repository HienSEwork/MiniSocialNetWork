namespace MiniSocialNetwork.Application.DTOs.Group;

public class GroupResponse
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string OwnerId { get; set; } = string.Empty;
    public int MemberCount { get; set; }
    public DateTime CreatedDate { get; set; }
    public IReadOnlyCollection<GroupMemberResponse> Members { get; set; } = Array.Empty<GroupMemberResponse>();
}

public sealed class GroupMemberResponse
{
    public string UserId { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public int Role { get; set; }
    public DateTime JoinedDate { get; set; }
}
