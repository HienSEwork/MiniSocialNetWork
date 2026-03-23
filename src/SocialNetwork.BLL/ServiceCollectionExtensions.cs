using Microsoft.Extensions.DependencyInjection;
using SocialNetwork.BLL.Interfaces;
using SocialNetwork.BLL.Services;

namespace SocialNetwork.BLL;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddSocialNetworkBll(this IServiceCollection services)
    {
        services.AddScoped<IPostService, PostService>();
        services.AddScoped<IGroupService, GroupService>();
        services.AddScoped<IChatService, ChatService>();
        services.AddScoped<IProfileService, ProfileService>();
        services.AddScoped<IDashboardService, DashboardService>();
        services.AddScoped<IFriendshipService, FriendshipService>();
        services.AddScoped<INotificationService, NotificationService>();

        return services;
    }
}
