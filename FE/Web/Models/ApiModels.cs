using System.Text.Json.Serialization;

namespace MiniSocialNetwork.Web.Models;

// ---- Auth ----
public sealed class AuthResponse
{
    public string Token { get; set; } = "";
    public DateTime ExpiresAt { get; set; }
    public UserProfile User { get; set; } = new();
}

public sealed class UserProfile
{
    public string Id { get; set; } = "";
    public string Email { get; set; } = "";
    public string DisplayName { get; set; } = "";
    public string? AvatarUrl { get; set; }
    public string? Bio { get; set; }
    public DateTime CreatedDate { get; set; }
    public IReadOnlyCollection<string> Roles { get; set; } = Array.Empty<string>();
}

public sealed class LoginRequest
{
    public string Email { get; set; } = "";
    public string Password { get; set; } = "";
}

public sealed class RegisterRequest
{
    public string Email { get; set; } = "";
    public string Password { get; set; } = "";
    public string DisplayName { get; set; } = "";
}

public sealed class ForgotPasswordRequest
{
    public string Email { get; set; } = "";
}

public sealed class ForgotPasswordResponse
{
    public string Message { get; set; } = "";
    public string? ResetToken { get; set; }
}

public sealed class ResetPasswordRequest
{
    public string Email { get; set; } = "";
    public string Token { get; set; } = "";
    public string NewPassword { get; set; } = "";
}

public sealed class UpdateProfileRequest
{
    public string DisplayName { get; set; } = "";
    public string? AvatarUrl { get; set; }
    public string? Bio { get; set; }
}

// ---- Posts ----
public sealed class PagedResult<T>
{
    public List<T> Items { get; set; } = new();
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int Total { get; set; }
}

public sealed class PostResponse
{
    public Guid Id { get; set; }
    public Guid? GroupId { get; set; }
    public string UserId { get; set; } = "";
    public string AuthorName { get; set; } = "";
    public string? AuthorAvatarUrl { get; set; }
    public string? GroupName { get; set; }
    public string Content { get; set; } = "";
    public string? MediaUrl { get; set; }
    public int MediaType { get; set; }
    public DateTime CreatedDate { get; set; }
    public DateTime? UpdatedDate { get; set; }
    public int CommentCount { get; set; }
    public int ReactionCount { get; set; }
    public Dictionary<int, int> ReactionCounts { get; set; } = new();
    public int? CurrentUserReaction { get; set; }
}

public sealed class CreatePostRequest
{
    public Guid? GroupId { get; set; }
    public string Content { get; set; } = "";
    public string? MediaUrl { get; set; }
    public int MediaType { get; set; }
}

public sealed class UploadResult
{
    public string Url { get; set; } = "";
    public int MediaType { get; set; }
}

// ---- Comments ----
public sealed class CommentResponse
{
    public Guid Id { get; set; }
    public Guid PostId { get; set; }
    public string UserId { get; set; } = "";
    public string AuthorName { get; set; } = "";
    public string? AuthorAvatarUrl { get; set; }
    public string Content { get; set; } = "";
    public DateTime CreatedDate { get; set; }
    public DateTime? UpdatedDate { get; set; }
}

public sealed class CommentRequest
{
    public string Content { get; set; } = "";
}

// ---- Reactions ----
public sealed class ReactionSummary
{
    public Guid PostId { get; set; }
    public int Total { get; set; }
    public Dictionary<int, int> Counts { get; set; } = new();
    public int? CurrentUserReaction { get; set; }
}

public sealed class ToggleReactionRequest
{
    public int Type { get; set; }
}

// ---- Groups ----
public sealed class GroupResponse
{
    public Guid Id { get; set; }
    public string Name { get; set; } = "";
    public string? Description { get; set; }
    public string? AvatarUrl { get; set; }
    public string OwnerId { get; set; } = "";
    public int MemberCount { get; set; }
    public DateTime CreatedDate { get; set; }
    public IReadOnlyCollection<GroupMember> Members { get; set; } = Array.Empty<GroupMember>();
}

public sealed class GroupMember
{
    public string UserId { get; set; } = "";
    public string DisplayName { get; set; } = "";
    public string? AvatarUrl { get; set; }
    public int Role { get; set; }
    public DateTime JoinedDate { get; set; }
}

public sealed class CreateGroupRequest
{
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
    public string? AvatarUrl { get; set; }
}

public sealed class ChangeRoleRequest
{
    public int Role { get; set; }
}

// ---- Chat ----
public sealed class ChatUser
{
    public string Id { get; set; } = "";
    public string DisplayName { get; set; } = "";
    public string? AvatarUrl { get; set; }
    public string? Bio { get; set; }
}

public sealed class MessageResponse
{
    public Guid Id { get; set; }
    public string SenderId { get; set; } = "";
    public string SenderName { get; set; } = "";
    public string? SenderAvatarUrl { get; set; }
    public string? ReceiverId { get; set; }
    public Guid? GroupId { get; set; }
    public string Content { get; set; } = "";
    public DateTime CreatedDate { get; set; }
    public bool IsGroupMessage { get; set; }
}

public sealed class SendMessageRequest
{
    public string? ReceiverId { get; set; }
    public Guid? GroupId { get; set; }
    public string Content { get; set; } = "";
}

// ---- Search ----
public sealed class SearchResponse
{
    public string Query { get; set; } = "";
    public int UserTotal { get; set; }
    public int GroupTotal { get; set; }
    public int PostTotal { get; set; }
    public IReadOnlyCollection<SearchUser> Users { get; set; } = Array.Empty<SearchUser>();
    public IReadOnlyCollection<SearchGroup> Groups { get; set; } = Array.Empty<SearchGroup>();
    public IReadOnlyCollection<PostResponse> Posts { get; set; } = Array.Empty<PostResponse>();
}

public sealed class SearchUser
{
    public string Id { get; set; } = "";
    public string DisplayName { get; set; } = "";
    public string? AvatarUrl { get; set; }
    public string? Bio { get; set; }
    public DateTime CreatedDate { get; set; }
}

public sealed class SearchGroup
{
    public Guid Id { get; set; }
    public string Name { get; set; } = "";
    public string Description { get; set; } = "";
    public string? AvatarUrl { get; set; }
    public string OwnerId { get; set; } = "";
    public int MemberCount { get; set; }
    public DateTime CreatedDate { get; set; }
}

// ---- Admin ----
public sealed class DashboardStats
{
    public int TotalUsers { get; set; }
    public int TotalPosts { get; set; }
    public int TotalComments { get; set; }
    public int TotalGroups { get; set; }
}

public sealed class PostsPerDayItem
{
    public DateTime Date { get; set; }
    public int Count { get; set; }
}

public sealed class AdminUser
{
    public string Id { get; set; } = "";
    public string? UserName { get; set; }
    public string? Email { get; set; }
    public string DisplayName { get; set; } = "";
    public string? AvatarUrl { get; set; }
    public DateTime CreatedDate { get; set; }
}

public sealed class ApiError
{
    [JsonPropertyName("message")] public string? Message { get; set; }
    [JsonPropertyName("error")] public string? Error { get; set; }
    [JsonPropertyName("title")] public string? Title { get; set; }
}
