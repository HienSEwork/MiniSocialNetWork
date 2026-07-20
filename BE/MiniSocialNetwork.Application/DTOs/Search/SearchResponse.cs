using MiniSocialNetwork.Application.DTOs.Post;

namespace MiniSocialNetwork.Application.DTOs.Search;

public sealed class SearchResponse
{
    public string Query { get; set; } = string.Empty;
    public int UserTotal { get; set; }
    public int GroupTotal { get; set; }
    public int PostTotal { get; set; }
    public IReadOnlyCollection<SearchUserResponse> Users { get; set; } = Array.Empty<SearchUserResponse>();
    public IReadOnlyCollection<SearchGroupResponse> Groups { get; set; } = Array.Empty<SearchGroupResponse>();
    public IReadOnlyCollection<PostResponse> Posts { get; set; } = Array.Empty<PostResponse>();
}

public sealed class SearchUserResponse
{
    public string Id { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public string? Bio { get; set; }
    public DateTime CreatedDate { get; set; }
}

public sealed class SearchGroupResponse
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string OwnerId { get; set; } = string.Empty;
    public int MemberCount { get; set; }
    public DateTime CreatedDate { get; set; }
}
