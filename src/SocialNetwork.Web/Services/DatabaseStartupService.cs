using System.Diagnostics;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SocialNetwork.DAL;
using SocialNetwork.DAL.Seeding;

namespace SocialNetwork.Web.Services;

public sealed class DatabaseStartupService(
    IServiceProvider serviceProvider,
    IConfiguration configuration,
    IOptions<DatabaseStartupOptions> options)
{
    public async Task InitializeAsync()
    {
        var settings = options.Value;
        if (!settings.AutoMigrateOnStartup && !settings.AutoSeedDemoDataOnStartup)
        {
            return;
        }

        await EnsureLocalDbRunningAsync(configuration.GetConnectionString("DefaultConnection"));

        await using var scope = serviceProvider.CreateAsyncScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();

        if (settings.AutoMigrateOnStartup)
        {
            await dbContext.Database.MigrateAsync();
        }

        if (settings.AutoSeedDemoDataOnStartup)
        {
            await DemoDataSeeder.SeedAsync(scope.ServiceProvider);
        }
    }

    private static async Task EnsureLocalDbRunningAsync(string? connectionString)
    {
        if (string.IsNullOrWhiteSpace(connectionString))
        {
            return;
        }

        var builder = new SqlConnectionStringBuilder(connectionString);
        var dataSource = builder.DataSource?.Trim();
        if (string.IsNullOrWhiteSpace(dataSource) ||
            !dataSource.StartsWith("(localdb)\\", StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        var separatorIndex = dataSource.IndexOf('\\');
        if (separatorIndex < 0 || separatorIndex == dataSource.Length - 1)
        {
            return;
        }

        var instanceName = dataSource[(separatorIndex + 1)..];
        var processStartInfo = new ProcessStartInfo
        {
            FileName = "sqllocaldb",
            RedirectStandardOutput = true,
            RedirectStandardError = true,
            UseShellExecute = false,
            CreateNoWindow = true
        };
        processStartInfo.ArgumentList.Add("start");
        processStartInfo.ArgumentList.Add(instanceName);

        using var process = Process.Start(processStartInfo);
        if (process is null)
        {
            throw new InvalidOperationException("Không thể khởi động LocalDB.");
        }

        await process.WaitForExitAsync();

        if (process.ExitCode != 0)
        {
            var error = await process.StandardError.ReadToEndAsync();
            if (!string.IsNullOrWhiteSpace(error) &&
                !error.Contains("already running", StringComparison.OrdinalIgnoreCase))
            {
                throw new InvalidOperationException($"Khởi động LocalDB thất bại: {error.Trim()}");
            }
        }
    }
}
