using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using SocialNetwork.DAL.Repositories;

namespace SocialNetwork.DAL;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddSocialNetworkDal(this IServiceCollection services)
        => AddSocialNetworkDal(services, configuration: null);

    public static IServiceCollection AddSocialNetworkDal(this IServiceCollection services, IConfiguration? configuration)
    {
        var connectionString = SocialNetworkDatabaseDefaults.ResolveConnectionString(configuration);

        services.AddDbContext<ApplicationDbContext>(
            options => options.UseSqlServer(connectionString),
            contextLifetime: ServiceLifetime.Scoped,
            optionsLifetime: ServiceLifetime.Singleton);

        services.AddDbContextFactory<ApplicationDbContext>(options =>
            options.UseSqlServer(connectionString));

        services.AddScoped<IPostRepository, PostRepository>();
        services.AddScoped<IGroupRepository, GroupRepository>();
        services.AddScoped<IFriendshipRepository, FriendshipRepository>();
        services.AddScoped<IChatRepository, ChatRepository>();
        services.AddScoped<INotificationRepository, NotificationRepository>();
        services.AddScoped<IProfileRepository, ProfileRepository>();
        services.AddScoped<IDashboardRepository, DashboardRepository>();

        return services;
    }
}
