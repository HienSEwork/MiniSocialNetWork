using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Localization;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using MiniSocialNetwork.API.Hubs;
using Microsoft.AspNetCore.Routing;
using MiniSocialNetwork.API.Middlewares;
using MiniSocialNetwork.API.Services;
using MiniSocialNetwork.Application.Interfaces;
using MiniSocialNetwork.Application.Interfaces.Repositories;
using MiniSocialNetwork.Application.Services;
using MiniSocialNetwork.Domain.Entities;
using MiniSocialNetwork.Infrastructure.Persistence;
using MiniSocialNetwork.Infrastructure.Repositories.Implementations;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddSignalR();
builder.Services.AddLocalization(options => options.ResourcesPath = "Resources");
builder.Services.Configure<RequestLocalizationOptions>(options =>
{
    var cultures = new[] { "vi", "en" };
    options.SetDefaultCulture("vi").AddSupportedCultures(cultures).AddSupportedUICultures(cultures);
});

builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));
builder.Services.AddIdentityCore<AppUser>(options =>
    {
        options.User.RequireUniqueEmail = true;
        options.Password.RequiredLength = 6;
        options.Password.RequireDigit = true;
        options.Password.RequireUppercase = false;
        options.Password.RequireNonAlphanumeric = false;
    })
    .AddRoles<IdentityRole>()
    .AddEntityFrameworkStores<AppDbContext>()
    .AddDefaultTokenProviders();

var jwtKey = builder.Configuration["Jwt:Key"]
    ?? throw new InvalidOperationException("Jwt:Key is required");
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
            ClockSkew = TimeSpan.FromMinutes(1)
        };
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var token = context.Request.Query["access_token"];
                if (!string.IsNullOrEmpty(token) && context.HttpContext.Request.Path.StartsWithSegments("/hubs"))
                    context.Token = token;
                return Task.CompletedTask;
            }
        };
    });
builder.Services.AddAuthorization();
builder.Services.AddCors(options => options.AddPolicy("MobileAndWeb", policy =>
    policy.AllowAnyHeader().AllowAnyMethod().SetIsOriginAllowed(_ => true).AllowCredentials()));

builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<ITokenService, JwtTokenService>();
builder.Services.AddScoped<IGroupService, GroupService>();
builder.Services.AddScoped<IGroupRepository, GroupRepository>();
builder.Services.AddScoped<IPostService, PostService>();
builder.Services.AddSingleton<IContentFilter, TfIdfContentFilter>();
builder.Services.AddScoped<IPostRepository, PostRepository>();
builder.Services.AddScoped<ICommentService, CommentService>();
builder.Services.AddScoped<ICommentRepository, CommentRepository>();
builder.Services.AddScoped<IReactionService, ReactionService>();
builder.Services.AddScoped<IReactionRepository, ReactionRepository>();
builder.Services.AddScoped<IStoryService, StoryService>();
builder.Services.AddScoped<IStoryRepository, StoryRepository>();
builder.Services.AddScoped<IChatService, ChatService>();
builder.Services.AddScoped<IMessageRepository, MessageRepository>();
builder.Services.AddScoped<ISearchService, SearchService>();
builder.Services.AddScoped<ISearchRepository, SearchRepository>();
builder.Services.AddScoped<IAdminService, AdminService>();
builder.Services.AddScoped<IAdminRepository, AdminRepository>();
builder.Services.AddSingleton<IRealtimeNotifier, SignalRRealtimeNotifier>();

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header
    });
    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        [new OpenApiSecurityScheme
        {
            Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
        }] = Array.Empty<string>()
    });
});

var app = builder.Build();
app.UseMiddleware<ExceptionMiddleware>();
app.UseRequestLocalization();
app.UseSwagger();
app.UseSwaggerUI();
if (!app.Environment.IsDevelopment()) app.UseHttpsRedirection();
app.UseDefaultFiles();
app.UseStaticFiles();
app.UseRouting();
app.UseCors("MobileAndWeb");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapHub<ChatHub>("/hubs/chat");
app.MapHub<NotificationHub>("/hubs/notifications");
// Log registered endpoints for debugging routing issues
var dataSource = app.Services.GetRequiredService<EndpointDataSource>();
Console.WriteLine("--- Registered endpoints ---");
foreach (var ep in dataSource.Endpoints)
{
    Console.WriteLine(ep.DisplayName ?? ep.ToString());
}
// Also write endpoints to a file for easier inspection
try
{
    // Give the app a moment to finish endpoint registration
    Task.Run(async () =>
    {
        await Task.Delay(1000);
        var lines = dataSource.Endpoints.Select(e =>
        {
            if (e is RouteEndpoint re)
                return $"{re.RoutePattern.RawText} :: {e.DisplayName}";
            return e.DisplayName ?? e.ToString();
        }).ToArray();
        System.IO.File.WriteAllLines("runtime_endpoints.txt", lines);
    });
}
catch { /* best-effort logging */ }
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await context.Database.MigrateAsync();
}
await IdentitySeeder.SeedRolesAsync(app.Services);
await DemoDataSeeder.SeedAsync(app.Services);
app.Run();
