using System.Security.Claims;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Mvc;
using MiniSocialNetwork.Web.Models;
using MiniSocialNetwork.Web.Services;

namespace MiniSocialNetwork.Web.Controllers;

public sealed class AccountController : Controller
{
    private readonly ApiClient _api;
    public AccountController(ApiClient api) => _api = api;

    [HttpGet]
    public IActionResult Login(string? returnUrl = null)
    {
        if (User.Identity?.IsAuthenticated == true) return RedirectToLocal(returnUrl);
        ViewData["ReturnUrl"] = returnUrl;
        return View();
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Login(LoginRequest req, string? returnUrl = null)
    {
        ViewData["ReturnUrl"] = returnUrl;
        try
        {
            var auth = await _api.LoginAsync(req);
            await SignInAsync(auth);
            return RedirectToLocal(returnUrl);
        }
        catch (ApiException ex)
        {
            ModelState.AddModelError(string.Empty, ex.Message);
            return View(req);
        }
    }

    [HttpGet]
    public IActionResult Register()
    {
        if (User.Identity?.IsAuthenticated == true) return RedirectToAction("Index", "Home");
        return View();
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Register(RegisterRequest req)
    {
        try
        {
            var auth = await _api.RegisterAsync(req);
            await SignInAsync(auth);
            return RedirectToAction("Index", "Home");
        }
        catch (ApiException ex)
        {
            ModelState.AddModelError(string.Empty, ex.Message);
            return View(req);
        }
    }

    [HttpGet]
    public IActionResult ForgotPassword() => View();

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ForgotPassword(ForgotPasswordRequest req)
    {
        try
        {
            var res = await _api.ForgotPasswordAsync(req);
            TempData["Info"] = res.Message;
            // Dev BE returns the reset token directly; forward it to make resetting easy.
            return RedirectToAction(nameof(ResetPassword), new { email = req.Email, token = res.ResetToken });
        }
        catch (ApiException ex)
        {
            ModelState.AddModelError(string.Empty, ex.Message);
            return View(req);
        }
    }

    [HttpGet]
    public IActionResult ResetPassword(string? email, string? token)
        => View(new ResetPasswordRequest { Email = email ?? "", Token = token ?? "" });

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> ResetPassword(ResetPasswordRequest req)
    {
        try
        {
            await _api.ResetPasswordAsync(req);
            TempData["Info"] = "Password updated. Please sign in.";
            return RedirectToAction(nameof(Login));
        }
        catch (ApiException ex)
        {
            ModelState.AddModelError(string.Empty, ex.Message);
            return View(req);
        }
    }

    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Logout()
    {
        await HttpContext.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        return RedirectToAction(nameof(Login));
    }

    private async Task SignInAsync(AuthResponse auth)
    {
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, auth.User.Id),
            new(ClaimTypes.Name, auth.User.DisplayName),
            new("displayName", auth.User.DisplayName),
            new("email", auth.User.Email),
            new("jwt", auth.Token),
        };
        if (!string.IsNullOrEmpty(auth.User.AvatarUrl))
            claims.Add(new Claim("avatarUrl", auth.User.AvatarUrl));
        foreach (var role in auth.User.Roles)
            claims.Add(new Claim(ClaimTypes.Role, role));

        var identity = new ClaimsIdentity(claims, CookieAuthenticationDefaults.AuthenticationScheme);
        await HttpContext.SignInAsync(
            CookieAuthenticationDefaults.AuthenticationScheme,
            new ClaimsPrincipal(identity),
            new AuthenticationProperties { IsPersistent = true, ExpiresUtc = auth.ExpiresAt });
    }

    private IActionResult RedirectToLocal(string? returnUrl)
        => Url.IsLocalUrl(returnUrl) ? Redirect(returnUrl!) : RedirectToAction("Index", "Home");
}
