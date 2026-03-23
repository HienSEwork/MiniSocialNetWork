using Microsoft.AspNetCore.Components.Authorization;
using Microsoft.AspNetCore.Identity;
using SocialNetwork.DAL.Entities;

namespace SocialNetwork.Web.Components.Account;

internal sealed class IdentityUserAccessor(
    UserManager<ApplicationUser> userManager,
    IdentityRedirectManager redirectManager,
    AuthenticationStateProvider authenticationStateProvider)
{
    public async Task<ApplicationUser> GetRequiredUserAsync(HttpContext? context)
    {
        var principal = context?.User ?? (await authenticationStateProvider.GetAuthenticationStateAsync()).User;
        var user = await userManager.GetUserAsync(principal);

        if (user is null)
        {
            var userId = userManager.GetUserId(principal);

            if (context is not null)
            {
                redirectManager.RedirectToWithStatus(
                    "Account/InvalidUser",
                    $"Lỗi: không thể tải tài khoản có mã '{userId}'.",
                    context);
            }

            throw new InvalidOperationException($"Không thể tải tài khoản có mã '{userId}'.");
        }

        return user;
    }
}

