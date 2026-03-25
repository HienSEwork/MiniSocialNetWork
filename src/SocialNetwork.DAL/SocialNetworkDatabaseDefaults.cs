using Microsoft.Extensions.Configuration;

namespace SocialNetwork.DAL;

public static class SocialNetworkDatabaseDefaults
{
    public const string DefaultConnectionString =
        "Server=.;Database=MiniSocialNetwork;User Id=sa;Password=dtpo9094;TrustServerCertificate=True;Encrypt=False;";

    public const bool AutoMigrateOnStartup = true;

    public const bool AutoSeedDemoDataOnStartup = true;

    public static string ResolveConnectionString(IConfiguration? configuration = null)
    {
        var environmentConnection = Environment.GetEnvironmentVariable("SOCIALNETWORK_CONNECTION_STRING");
        if (!string.IsNullOrWhiteSpace(environmentConnection))
        {
            return environmentConnection;
        }

        var configuredConnection = configuration?.GetConnectionString("DefaultConnection");
        return string.IsNullOrWhiteSpace(configuredConnection)
            ? DefaultConnectionString
            : configuredConnection;
    }
}
