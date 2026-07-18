using Microsoft.AspNetCore.Identity;

namespace MiniSocialNetwork.Domain.Entities;

public class AppUser : IdentityUser
{
    public string DisplayName { get; set; }
    public string? AvatarUrl { get; set; }
    public string? Bio { get; set; }
    public DateTime CreatedDate { get; set; }

    public ICollection<Group> OwnedGroups { get; set; }
    public ICollection<GroupMember> GroupMembers { get; set; }
}