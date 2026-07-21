namespace MiniSocialNetwork.Domain.Entities;

public class UserAchievement
{
    public string UserId { get; set; } = string.Empty;
    public AppUser User { get; set; } = null!;
    public string AchievementCode { get; set; } = string.Empty;
    public AchievementDefinition Achievement { get; set; } = null!;
    public DateTime UnlockedAt { get; set; }
}
