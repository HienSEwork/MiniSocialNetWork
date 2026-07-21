using MiniSocialNetwork.Application.DTOs.Reaction;

namespace MiniSocialNetwork.Application.Interfaces;

public interface IReactionService
{
    Task<ReactionSummaryResponse> GetSummaryAsync(Guid postId, string? userId);
    Task<ReactionSummaryResponse> ToggleAsync(Guid postId, int type, string userId);
}
