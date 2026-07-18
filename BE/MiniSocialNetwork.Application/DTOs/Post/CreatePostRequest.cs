namespace MiniSocialNetwork.Application.DTOs.Post;

public class CreatePostRequest
{
    public string Content { get; set; } = string.Empty;
    public string? MediaUrl { get; set; }
    public int MediaType { get; set; }
}
