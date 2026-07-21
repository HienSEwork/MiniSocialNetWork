using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MiniSocialNetwork.Application.DTOs.Friend;

public class RecommendationResponse
{
    public string Id { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }

    // counts used to explain recommendation
    public int MutualFriends { get; set; }
    public int SharedGroups { get; set; }

    // 0 = None, 1 = Friends, 2 = PendingOutgoing, 3 = PendingIncoming, 4 = DeclinedRecently
    public int RelationshipStatus { get; set; }
}
