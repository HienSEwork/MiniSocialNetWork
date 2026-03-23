namespace SocialNetwork.Web.Services;

public sealed class DatabaseStartupOptions
{
    public bool AutoMigrateOnStartup { get; set; }

    public bool AutoSeedDemoDataOnStartup { get; set; }
}
