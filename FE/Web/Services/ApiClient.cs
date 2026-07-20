using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using MiniSocialNetwork.Web.Models;

namespace MiniSocialNetwork.Web.Services;

public sealed class ApiException : Exception
{
    public HttpStatusCode StatusCode { get; }
    public ApiException(HttpStatusCode statusCode, string message) : base(message) => StatusCode = statusCode;
}

public sealed class ApiClient
{
    private readonly HttpClient _http;
    private readonly IHttpContextAccessor _ctx;
    private static readonly JsonSerializerOptions Json = new(JsonSerializerDefaults.Web);

    public ApiClient(HttpClient http, IHttpContextAccessor ctx)
    {
        _http = http;
        _ctx = ctx;
    }

    public string BaseUrl => _http.BaseAddress?.ToString().TrimEnd('/') ?? "";

    private void Authorize()
    {
        var token = _ctx.HttpContext?.User.FindFirst("jwt")?.Value;
        _http.DefaultRequestHeaders.Authorization = string.IsNullOrEmpty(token)
            ? null
            : new AuthenticationHeaderValue("Bearer", token);
    }

    private async Task<T> Read<T>(HttpResponseMessage res)
    {
        await EnsureSuccess(res);
        var data = await res.Content.ReadFromJsonAsync<T>(Json);
        return data!;
    }

    private static async Task EnsureSuccess(HttpResponseMessage res)
    {
        if (res.IsSuccessStatusCode) return;
        var body = await res.Content.ReadAsStringAsync();
        var message = res.ReasonPhrase ?? "Request failed";
        try
        {
            var err = JsonSerializer.Deserialize<ApiError>(body, Json);
            message = err?.Message ?? err?.Error ?? err?.Title ?? (string.IsNullOrWhiteSpace(body) ? message : body);
        }
        catch { if (!string.IsNullOrWhiteSpace(body)) message = body; }
        throw new ApiException(res.StatusCode, message);
    }

    // ---- Auth ----
    public async Task<AuthResponse> LoginAsync(LoginRequest req)
    {
        var res = await _http.PostAsJsonAsync("/api/auth/login", req, Json);
        return await Read<AuthResponse>(res);
    }

    public async Task<AuthResponse> RegisterAsync(RegisterRequest req)
    {
        var res = await _http.PostAsJsonAsync("/api/auth/register", req, Json);
        return await Read<AuthResponse>(res);
    }

    public async Task<ForgotPasswordResponse> ForgotPasswordAsync(ForgotPasswordRequest req)
    {
        var res = await _http.PostAsJsonAsync("/api/auth/forgot-password", req, Json);
        return await Read<ForgotPasswordResponse>(res);
    }

    public async Task ResetPasswordAsync(ResetPasswordRequest req)
    {
        var res = await _http.PostAsJsonAsync("/api/auth/reset-password", req, Json);
        await EnsureSuccess(res);
    }

    public async Task<UserProfile> MeAsync()
    {
        Authorize();
        var res = await _http.GetAsync("/api/auth/me");
        return await Read<UserProfile>(res);
    }

    // ---- Profiles ----
    public async Task<UserProfile> GetProfileAsync(string userId)
    {
        Authorize();
        var res = await _http.GetAsync($"/api/profiles/{userId}");
        return await Read<UserProfile>(res);
    }

    public async Task<UserProfile> UpdateProfileAsync(UpdateProfileRequest req)
    {
        Authorize();
        var res = await _http.PutAsJsonAsync("/api/profiles/me", req, Json);
        return await Read<UserProfile>(res);
    }

    // ---- Posts ----
    public async Task<PagedResult<PostResponse>> GetFeedAsync(int page = 1, int pageSize = 10)
    {
        Authorize();
        var res = await _http.GetAsync($"/api/posts?page={page}&pageSize={pageSize}");
        return await Read<PagedResult<PostResponse>>(res);
    }

    public async Task<PostResponse> GetPostAsync(Guid id)
    {
        Authorize();
        var res = await _http.GetAsync($"/api/posts/{id}");
        return await Read<PostResponse>(res);
    }

    public async Task CreatePostAsync(CreatePostRequest req)
    {
        Authorize();
        var res = await _http.PostAsJsonAsync("/api/posts", req, Json);
        await EnsureSuccess(res);
    }

    public async Task UpdatePostAsync(Guid id, CreatePostRequest req)
    {
        Authorize();
        var res = await _http.PutAsJsonAsync($"/api/posts/{id}", req, Json);
        await EnsureSuccess(res);
    }

    public async Task DeletePostAsync(Guid id)
    {
        Authorize();
        var res = await _http.DeleteAsync($"/api/posts/{id}");
        await EnsureSuccess(res);
    }

    // ---- Comments ----
    public async Task<List<CommentResponse>> GetCommentsAsync(Guid postId)
    {
        Authorize();
        var res = await _http.GetAsync($"/api/posts/{postId}/comments");
        return await Read<List<CommentResponse>>(res);
    }

    public async Task<CommentResponse> AddCommentAsync(Guid postId, string content)
    {
        Authorize();
        var res = await _http.PostAsJsonAsync($"/api/posts/{postId}/comments", new CommentRequest { Content = content }, Json);
        return await Read<CommentResponse>(res);
    }

    public async Task UpdateCommentAsync(Guid postId, Guid commentId, string content)
    {
        Authorize();
        var res = await _http.PutAsJsonAsync($"/api/posts/{postId}/comments/{commentId}", new CommentRequest { Content = content }, Json);
        await EnsureSuccess(res);
    }

    public async Task DeleteCommentAsync(Guid postId, Guid commentId)
    {
        Authorize();
        var res = await _http.DeleteAsync($"/api/posts/{postId}/comments/{commentId}");
        await EnsureSuccess(res);
    }

    // ---- Reactions ----
    public async Task<ReactionSummary> GetReactionsAsync(Guid postId)
    {
        Authorize();
        var res = await _http.GetAsync($"/api/posts/{postId}/reactions");
        return await Read<ReactionSummary>(res);
    }

    public async Task<ReactionSummary> ToggleReactionAsync(Guid postId, int type)
    {
        Authorize();
        var res = await _http.PostAsJsonAsync($"/api/posts/{postId}/reactions", new ToggleReactionRequest { Type = type }, Json);
        return await Read<ReactionSummary>(res);
    }

    // ---- Groups ----
    public async Task<List<GroupResponse>> GetGroupsAsync()
    {
        Authorize();
        var res = await _http.GetAsync("/api/groups");
        return await Read<List<GroupResponse>>(res);
    }

    public async Task<List<GroupResponse>> GetMyGroupsAsync()
    {
        Authorize();
        var res = await _http.GetAsync("/api/groups/mine");
        return await Read<List<GroupResponse>>(res);
    }

    public async Task<GroupResponse?> GetGroupAsync(Guid id)
    {
        Authorize();
        var res = await _http.GetAsync($"/api/groups/{id}");
        if (res.StatusCode == HttpStatusCode.NotFound) return null;
        return await Read<GroupResponse>(res);
    }

    public async Task<Guid> CreateGroupAsync(CreateGroupRequest req)
    {
        Authorize();
        var res = await _http.PostAsJsonAsync("/api/groups", req, Json);
        await EnsureSuccess(res);
        var doc = await res.Content.ReadFromJsonAsync<JsonElement>();
        return doc.GetProperty("id").GetGuid();
    }

    public async Task UpdateGroupAsync(Guid id, CreateGroupRequest req)
    {
        Authorize();
        var res = await _http.PutAsJsonAsync($"/api/groups/{id}", req, Json);
        await EnsureSuccess(res);
    }

    public async Task DeleteGroupAsync(Guid id)
    {
        Authorize();
        var res = await _http.DeleteAsync($"/api/groups/{id}");
        await EnsureSuccess(res);
    }

    public async Task JoinGroupAsync(Guid id)
    {
        Authorize();
        var res = await _http.PostAsync($"/api/groups/{id}/join", null);
        await EnsureSuccess(res);
    }

    public async Task LeaveGroupAsync(Guid id)
    {
        Authorize();
        var res = await _http.PostAsync($"/api/groups/{id}/leave", null);
        await EnsureSuccess(res);
    }

    public async Task KickMemberAsync(Guid id, string userId)
    {
        Authorize();
        var res = await _http.DeleteAsync($"/api/groups/{id}/members/{userId}");
        await EnsureSuccess(res);
    }

    public async Task ChangeRoleAsync(Guid id, string userId, int role)
    {
        Authorize();
        var res = await _http.PutAsJsonAsync($"/api/groups/{id}/members/{userId}/role", new ChangeRoleRequest { Role = role }, Json);
        await EnsureSuccess(res);
    }

    public async Task<PagedResult<PostResponse>> GetGroupFeedAsync(Guid groupId, int page = 1, int pageSize = 20)
    {
        Authorize();
        var res = await _http.GetAsync($"/api/groups/{groupId}/posts?page={page}&pageSize={pageSize}");
        return await Read<PagedResult<PostResponse>>(res);
    }

    // ---- Chat ----
    public async Task<List<ChatUser>> GetChatUsersAsync(string? keyword = null)
    {
        Authorize();
        var url = "/api/chat/users" + (string.IsNullOrWhiteSpace(keyword) ? "" : $"?keyword={Uri.EscapeDataString(keyword)}");
        var res = await _http.GetAsync(url);
        return await Read<List<ChatUser>>(res);
    }

    public async Task<List<MessageResponse>> GetPrivateHistoryAsync(string otherUserId, int take = 100)
    {
        Authorize();
        var res = await _http.GetAsync($"/api/chat/private/{otherUserId}?take={take}");
        return await Read<List<MessageResponse>>(res);
    }

    public async Task<List<MessageResponse>> GetGroupHistoryAsync(Guid groupId, int take = 100)
    {
        Authorize();
        var res = await _http.GetAsync($"/api/chat/groups/{groupId}?take={take}");
        return await Read<List<MessageResponse>>(res);
    }

    public async Task<MessageResponse> SendMessageAsync(SendMessageRequest req)
    {
        Authorize();
        var res = await _http.PostAsJsonAsync("/api/chat/messages", req, Json);
        return await Read<MessageResponse>(res);
    }

    // ---- Search ----
    public async Task<SearchResponse> SearchAsync(string query, int limit = 10)
    {
        Authorize();
        var res = await _http.GetAsync($"/api/search?q={Uri.EscapeDataString(query)}&limit={limit}");
        return await Read<SearchResponse>(res);
    }

    // ---- Media ----
    public async Task<UploadResult> UploadAsync(Stream stream, string fileName, string contentType)
    {
        Authorize();
        using var content = new MultipartFormDataContent();
        var fileContent = new StreamContent(stream);
        fileContent.Headers.ContentType = new MediaTypeHeaderValue(string.IsNullOrEmpty(contentType) ? "application/octet-stream" : contentType);
        content.Add(fileContent, "file", fileName);
        var res = await _http.PostAsync("/api/media/upload", content);
        return await Read<UploadResult>(res);
    }

    // ---- Admin ----
    public async Task<DashboardStats> GetStatsAsync()
    {
        Authorize();
        var res = await _http.GetAsync("/api/admin/stats");
        return await Read<DashboardStats>(res);
    }

    public async Task<List<PostsPerDayItem>> GetPostsPerDayAsync(int days = 7)
    {
        Authorize();
        var res = await _http.GetAsync($"/api/admin/posts-per-day?days={days}");
        return await Read<List<PostsPerDayItem>>(res);
    }

    public async Task<PagedResult<AdminUser>> GetUsersAsync(string? keyword, int page = 1, int pageSize = 10)
    {
        Authorize();
        var url = $"/api/admin/users?page={page}&pageSize={pageSize}" + (string.IsNullOrWhiteSpace(keyword) ? "" : $"&keyword={Uri.EscapeDataString(keyword)}");
        var res = await _http.GetAsync(url);
        return await Read<PagedResult<AdminUser>>(res);
    }

    public async Task DeleteUserAsync(string userId)
    {
        Authorize();
        var res = await _http.DeleteAsync($"/api/admin/users/{userId}");
        await EnsureSuccess(res);
    }
}
