namespace MiniSocialNetwork.Application.DTOs.Admin;

public class UserResponse
{
    public string Id { get; set; } = string.Empty;
    public string? UserName { get; set; }
    public string? Email { get; set; }
    public string DisplayName { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public DateTime CreatedDate { get; set; }
}
