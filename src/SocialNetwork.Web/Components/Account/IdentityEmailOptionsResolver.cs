using Microsoft.Extensions.Configuration;

namespace SocialNetwork.Web.Components.Account;

internal static class IdentityEmailOptionsResolver
{
    public static IdentityEmailOptions Resolve(IConfiguration configuration)
    {
        return new IdentityEmailOptions
        {
            Host = GetValue(configuration, "SOCIALNETWORK_SMTP_HOST", "Mail:Smtp:Host"),
            Port = GetIntValue(configuration, "SOCIALNETWORK_SMTP_PORT", "Mail:Smtp:Port", 587),
            UserName = GetValue(configuration, "SOCIALNETWORK_SMTP_USERNAME", "Mail:Smtp:Username"),
            Password = GetValue(configuration, "SOCIALNETWORK_SMTP_PASSWORD", "Mail:Smtp:Password"),
            FromEmail = GetValue(configuration, "SOCIALNETWORK_SMTP_FROM_EMAIL", "Mail:Smtp:FromEmail"),
            FromName = GetValue(configuration, "SOCIALNETWORK_SMTP_FROM_NAME", "Mail:Smtp:FromName") ?? "Mini Social",
            EnableSsl = GetBoolValue(configuration, "SOCIALNETWORK_SMTP_ENABLE_SSL", "Mail:Smtp:EnableSsl", true),
            UseDefaultCredentials = GetBoolValue(configuration, "SOCIALNETWORK_SMTP_USE_DEFAULT_CREDENTIALS", "Mail:Smtp:UseDefaultCredentials", false),
            PickupDirectory = GetValue(configuration, "SOCIALNETWORK_SMTP_PICKUP_DIRECTORY", "Mail:Smtp:PickupDirectory")
        };
    }

    private static string? GetValue(IConfiguration configuration, string environmentKey, string configurationKey)
    {
        var value = Environment.GetEnvironmentVariable(environmentKey);
        return string.IsNullOrWhiteSpace(value) ? configuration[configurationKey] : value;
    }

    private static int GetIntValue(IConfiguration configuration, string environmentKey, string configurationKey, int fallback)
    {
        var value = GetValue(configuration, environmentKey, configurationKey);
        return int.TryParse(value, out var result) ? result : fallback;
    }

    private static bool GetBoolValue(IConfiguration configuration, string environmentKey, string configurationKey, bool fallback)
    {
        var value = GetValue(configuration, environmentKey, configurationKey);
        return bool.TryParse(value, out var result) ? result : fallback;
    }
}
