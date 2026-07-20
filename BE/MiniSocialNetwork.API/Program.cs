using Microsoft.AspNetCore.Localization;
using Microsoft.EntityFrameworkCore;
using MiniSocialNetwork.API.Middlewares;
using MiniSocialNetwork.API.Hubs;
using MiniSocialNetwork.Application.Interfaces;
using MiniSocialNetwork.Application.Interfaces.Repositories;
using MiniSocialNetwork.Application.Services;
using MiniSocialNetwork.Infrastructure.Persistence;
using MiniSocialNetwork.Infrastructure.Repositories.Implementations;

var builder = WebApplication.CreateBuilder(args);

// Controller
builder.Services.AddControllers();

// Localization (Vi / En)
builder.Services.AddLocalization(options => options.ResourcesPath = "Resources");

var supportedCultures = new[] { "vi", "en" };
builder.Services.Configure<RequestLocalizationOptions>(options =>
{
    options.SetDefaultCulture("vi")
        .AddSupportedCultures(supportedCultures)
        .AddSupportedUICultures(supportedCultures);
});

// DbContext
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// DI - application / repository
builder.Services.AddScoped<IGroupService, GroupService>();
builder.Services.AddScoped<IGroupRepository, GroupRepository>();
builder.Services.AddScoped<IPostService, PostService>();
builder.Services.AddScoped<IPostRepository, PostRepository>();
builder.Services.AddScoped<IAdminService, AdminService>();
builder.Services.AddScoped<IAdminRepository, AdminRepository>();

// Chat DI
builder.Services.AddScoped<IMessageRepository, MessageRepository>();
builder.Services.AddScoped<IChatService, ChatService>();

// SignalR
builder.Services.AddSignalR(options =>
{
    options.EnableDetailedErrors = true;
});

// Optional: allow browser clients (e.g. local SPA) to connect. Adjust origins for production.
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy
            .AllowAnyHeader()
            .AllowAnyMethod()
            .SetIsOriginAllowed(_ => true)
            .AllowCredentials();
    });
});

// Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

app.UseMiddleware<ExceptionMiddleware>();

app.UseRequestLocalization();

app.UseSwagger();
app.UseSwaggerUI();

app.UseHttpsRedirection();

// Ensure routing and CORS run before hubs/endpoints
app.UseRouting();
app.UseCors("AllowAll");

app.UseAuthorization();

app.MapControllers();

// Map SignalR hubs after routing is configured
app.MapHub<ChatHub>("/chatHub");
app.MapHub<NotificationHub>("/notificationHub");

app.Run();