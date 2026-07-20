using Microsoft.AspNetCore.Identity;

namespace MiniSocialNetwork.Domain.Entities;

public class AppUser : IdentityUser
{
    public string DisplayName { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public string? Bio { get; set; }
    public DateTime CreatedDate { get; set; }
    public bool IsDeleted { get; set; }
    public ICollection<Group> OwnedGroups { get; set; } = new List<Group>();
    public ICollection<GroupMember> GroupMembers { get; set; } = new List<GroupMember>();
}
