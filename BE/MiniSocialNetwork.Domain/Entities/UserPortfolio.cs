namespace MiniSocialNetwork.Domain.Entities;

public class UserPortfolio
{
    public string UserId { get; set; } = string.Empty;
    public AppUser User { get; set; } = null!;
    public string Title { get; set; } = string.Empty;
    public string Bio { get; set; } = string.Empty;
    public string Skills { get; set; } = string.Empty;
    public string? GithubUrl { get; set; }
    public string? WebsiteUrl { get; set; }
    public string? Location { get; set; }
    public string? FeaturedProjectName { get; set; }
    public string? FeaturedProjectUrl { get; set; }
    public DateTime UpdatedDate { get; set; }
}
