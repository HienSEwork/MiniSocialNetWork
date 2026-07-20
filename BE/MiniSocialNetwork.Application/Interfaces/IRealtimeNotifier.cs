using MiniSocialNetwork.Application.DTOs.Reaction;

namespace MiniSocialNetwork.Application.Interfaces;

public interface IRealtimeNotifier
{
    Task ReactionChangedAsync(ReactionSummaryResponse summary);
    Task NotifyUserAsync(string userId, object notification);
}
