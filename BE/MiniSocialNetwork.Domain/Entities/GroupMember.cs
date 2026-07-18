using MiniSocialNetwork.Domain.Entities;

namespace MiniSocialNetwork.Domain.Entities;

public class GroupMember
{
    public Guid GroupId { get; set; }
    public Group Group { get; set; }

    public string UserId { get; set; }

    // 👇 BẮT BUỘC PHẢI CÓ DÒNG NÀY
    public AppUser User { get; set; }

    public int Role { get; set; }
    public DateTime JoinedDate { get; set; }
}