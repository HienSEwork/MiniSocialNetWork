using System.Globalization;
using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.AspNetCore.Localization;
using Microsoft.AspNetCore.Identity;
using SocialNetwork.Web.Configuration;
using SocialNetwork.Web.Components;
using SocialNetwork.Web.Components.Account;
using SocialNetwork.Web.Hubs;
using SocialNetwork.Web.Services;
using SocialNetwork.BLL;
using SocialNetwork.DAL;
using SocialNetwork.DAL.Entities;
using SocialNetwork.DAL.Seeding;

DotEnvLoader.Load();

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
builder.Services.AddRazorComponents()
    .AddInteractiveServerComponents();

builder.Services.AddCascadingAuthenticationState();
builder.Services.AddScoped<IdentityUserAccessor>();
builder.Services.AddScoped<IdentityRedirectManager>();
builder.Services.AddScoped<AuthenticationStateProvider, IdentityRevalidatingAuthenticationStateProvider>();
builder.Services.AddScoped<CurrentUserService>();
builder.Services.AddScoped<NotificationBroadcastService>();
builder.Services.AddSingleton<IdentityLinkStore>();
builder.Services.AddSingleton(sp => IdentityEmailOptionsResolver.Resolve(sp.GetRequiredService<IConfiguration>()));
builder.Services.AddSingleton<DatabaseStartupService>();
builder.Services.AddSocialNetworkDal();
builder.Services.AddSocialNetworkBll();
builder.Services.AddLocalization();
builder.Services.AddSignalR();

builder.Services.AddAuthentication(options =>
    {
        options.DefaultScheme = IdentityConstants.ApplicationScheme;
        options.DefaultSignInScheme = IdentityConstants.ExternalScheme;
    })
    .AddIdentityCookies();

builder.Services.AddDatabaseDeveloperPageExceptionFilter();

builder.Services.AddIdentityCore<ApplicationUser>(options =>
    {
        options.SignIn.RequireConfirmedAccount = false;
        options.User.RequireUniqueEmail = true;
        options.Password.RequireDigit = true;
        options.Password.RequireLowercase = true;
        options.Password.RequireUppercase = false;
        options.Password.RequireNonAlphanumeric = false;
    })
    .AddRoles<IdentityRole>()
    .AddEntityFrameworkStores<ApplicationDbContext>()
    .AddSignInManager()
    .AddDefaultTokenProviders();

builder.Services.AddSingleton<IEmailSender<ApplicationUser>, IdentitySmtpEmailSender>();

var app = builder.Build();

var supportedCultures = new[] { new CultureInfo("vi"), new CultureInfo("en") };
app.UseRequestLocalization(new RequestLocalizationOptions
{
    DefaultRequestCulture = new Microsoft.AspNetCore.Localization.RequestCulture("vi"),
    SupportedCultures = supportedCultures,
    SupportedUICultures = supportedCultures
});

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseMigrationsEndPoint();
}
else
{
    app.UseExceptionHandler("/Error", createScopeForErrors: true);
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseStaticFiles();
app.UseAntiforgery();

app.MapRazorComponents<App>()
    .AddInteractiveServerRenderMode();
app.MapHub<ChatHub>("/hubs/chat");
app.MapHub<NotificationHub>("/hubs/notifications");

// Add additional endpoints required by the Identity /Account Razor components.
app.MapAdditionalIdentityEndpoints();
app.MapGet("/preferences/set-language", (string culture, string? returnUrl, HttpContext httpContext) =>
{
    var normalizedCulture = string.Equals(culture, "en", StringComparison.OrdinalIgnoreCase) ? "en" : "vi";
    var cookieValue = CookieRequestCultureProvider.MakeCookieValue(new RequestCulture(normalizedCulture));

    httpContext.Response.Cookies.Append(
        CookieRequestCultureProvider.DefaultCookieName,
        cookieValue,
        new CookieOptions
        {
            Expires = DateTimeOffset.UtcNow.AddYears(1),
            IsEssential = true,
            SameSite = SameSiteMode.Lax,
            Path = "/"
        });

    var safeReturnUrl = !string.IsNullOrWhiteSpace(returnUrl)
        && Uri.TryCreate(returnUrl, UriKind.Relative, out _)
        && returnUrl.StartsWith("/", StringComparison.Ordinal)
        && !returnUrl.StartsWith("//", StringComparison.Ordinal)
            ? returnUrl
            : "/settings";

    return Results.LocalRedirect(safeReturnUrl);
});

await app.Services.GetRequiredService<DatabaseStartupService>().InitializeAsync();

app.Run();

