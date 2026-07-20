using System.Security.Claims;

namespace MiniSocialNetwork.Web.Services;

public static class UiHelpers
{
    public static readonly IReadOnlyDictionary<int, (string Emoji, string Label)> Reactions =
        new Dictionary<int, (string, string)>
        {
            [1] = ("\U0001F44D", "Like"),
            [2] = ("\u2764\uFE0F", "Love"),
            [3] = ("\U0001F604", "Haha"),
        };

    public static string ReactionEmoji(int type) =>
        Reactions.TryGetValue(type, out var r) ? r.Emoji : "\U0001F44D";

    public static string ReactionLabel(int type) =>
        Reactions.TryGetValue(type, out var r) ? r.Label : "Like";

    public static string RoleName(int role) => role switch
    {
        2 => "Owner",
        1 => "Admin",
        _ => "Member"
    };

    /// <summary>Absolute media URL, or null when the stored value is a relative/asset path we cannot resolve.</summary>
    public static string? Media(string? url)
    {
        if (string.IsNullOrWhiteSpace(url)) return null;
        return url.StartsWith("http://") || url.StartsWith("https://") ? url : null;
    }

    /// <summary>An avatar URL that always resolves: the stored URL when absolute, otherwise a generated initials avatar.</summary>
    public static string Avatar(string? url, string? name)
    {
        var resolved = Media(url);
        if (resolved != null) return resolved;
        var seed = Uri.EscapeDataString(string.IsNullOrWhiteSpace(name) ? "User" : name);
        return $"https://api.dicebear.com/9.x/initials/svg?seed={seed}";
    }

    public static string TimeAgo(DateTime utc, bool english)
    {
        var span = DateTime.UtcNow - DateTime.SpecifyKind(utc, DateTimeKind.Utc);
        if (span.TotalSeconds < 60) return english ? "just now" : "vừa xong";
        if (span.TotalMinutes < 60) return $"{(int)span.TotalMinutes}{(english ? "m" : " phút")}";
        if (span.TotalHours < 24) return $"{(int)span.TotalHours}{(english ? "h" : " giờ")}";
        if (span.TotalDays < 7) return $"{(int)span.TotalDays}{(english ? "d" : " ngày")}";
        return utc.ToLocalTime().ToString("dd/MM/yyyy");
    }

    // ---- Current user helpers (from cookie claims) ----
    public static string? UserId(this ClaimsPrincipal user) =>
        user.FindFirst(ClaimTypes.NameIdentifier)?.Value;

    public static string DisplayName(this ClaimsPrincipal user) =>
        user.FindFirst("displayName")?.Value ?? user.Identity?.Name ?? "";

    public static string? AvatarUrl(this ClaimsPrincipal user) =>
        user.FindFirst("avatarUrl")?.Value;

    public static bool IsAdmin(this ClaimsPrincipal user) => user.IsInRole("Admin");
}
