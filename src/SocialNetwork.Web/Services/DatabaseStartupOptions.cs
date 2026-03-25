using SocialNetwork.DAL;

namespace SocialNetwork.Web.Services;

public sealed class DatabaseStartupOptions
{
    public bool AutoMigrateOnStartup { get; set; } = SocialNetworkDatabaseDefaults.AutoMigrateOnStartup;

    public bool AutoSeedDemoDataOnStartup { get; set; } = SocialNetworkDatabaseDefaults.AutoSeedDemoDataOnStartup;
}
