using System.Security.Claims;
using Microsoft.AspNetCore.Identity;
using SocialNetwork.DAL.Entities;

namespace SocialNetwork.Web.Services;

public class CurrentUserService(UserManager<ApplicationUser> userManager)
{
    public async Task<ApplicationUser> GetRequiredUserAsync(ClaimsPrincipal principal)
    {
        var user = await userManager.GetUserAsync(principal);
        return user ?? throw new InvalidOperationException("Không tải được thông tin người dùng đã đăng nhập.");
    }

    public Task<string> GetRequiredUserIdAsync(ClaimsPrincipal principal)
    {
        var userId = principal.FindFirstValue(ClaimTypes.NameIdentifier);
        return !string.IsNullOrWhiteSpace(userId)
            ? Task.FromResult(userId)
            : throw new InvalidOperationException("Không tải được mã người dùng đã đăng nhập.");
    }
}
