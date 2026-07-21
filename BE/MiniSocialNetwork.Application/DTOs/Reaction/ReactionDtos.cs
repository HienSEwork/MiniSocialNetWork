namespace MiniSocialNetwork.Application.DTOs.Reaction;

public sealed class ToggleReactionRequest
{
    public int Type { get; set; }
}

public sealed class ReactionSummaryResponse
{
    public Guid PostId { get; set; }
    public int Total { get; set; }
    public IReadOnlyDictionary<int, int> Counts { get; set; } = new Dictionary<int, int>();
    public int? CurrentUserReaction { get; set; }
}
