using System.Collections.Concurrent;

namespace SocialNetwork.Web.Components.Account;

internal sealed class IdentityLinkStore
{
    private readonly ConcurrentDictionary<string, string> confirmationLinks = new(StringComparer.OrdinalIgnoreCase);
    private readonly ConcurrentDictionary<string, string> passwordResetLinks = new(StringComparer.OrdinalIgnoreCase);

    public void SaveConfirmationLink(string email, string link)
    {
        var key = NormalizeKey(email);
        if (key is not null && !string.IsNullOrWhiteSpace(link))
        {
            confirmationLinks[key] = link;
        }
    }

    public void SavePasswordResetLink(string email, string link)
    {
        var key = NormalizeKey(email);
        if (key is not null && !string.IsNullOrWhiteSpace(link))
        {
            passwordResetLinks[key] = link;
        }
    }

    public string? GetConfirmationLink(string? email)
    {
        var key = NormalizeKey(email);
        return key is not null && confirmationLinks.TryGetValue(key, out var link)
            ? link
            : null;
    }

    public string? GetPasswordResetLink(string? email)
    {
        var key = NormalizeKey(email);
        return key is not null && passwordResetLinks.TryGetValue(key, out var link)
            ? link
            : null;
    }

    private static string? NormalizeKey(string? email) =>
        string.IsNullOrWhiteSpace(email) ? null : email.Trim().ToUpperInvariant();
}
