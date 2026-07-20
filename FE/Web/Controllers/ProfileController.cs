using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using MiniSocialNetwork.Web.Models;
using MiniSocialNetwork.Web.Services;

namespace MiniSocialNetwork.Web.Controllers;

public sealed class ProfileController : Controller
{
    private readonly ApiClient _api;
    public ProfileController(ApiClient api) => _api = api;

    [HttpGet]
    public async Task<IActionResult> Index(string? id)
    {
        var uid = User.UserId();
        var targetId = string.IsNullOrEmpty(id) ? uid : id;
        if (string.IsNullOrEmpty(targetId)) return RedirectToAction("Login", "Account");
        try
        {
            var profile = await _api.GetProfileAsync(targetId);
            return View(new ProfileViewModel { Profile = profile, IsMe = targetId == uid });
        }
        catch (ApiException) { return NotFound(); }
    }

    [Authorize, HttpGet]
    public async Task<IActionResult> Edit()
    {
        var uid = User.UserId()!;
        var profile = await _api.GetProfileAsync(uid);
        return View(new UpdateProfileRequest
        {
            DisplayName = profile.DisplayName,
            AvatarUrl = profile.AvatarUrl,
            Bio = profile.Bio
        });
    }

    [Authorize, HttpPost, ValidateAntiForgeryToken]
    [RequestSizeLimit(52_428_800)]
    public async Task<IActionResult> Edit(UpdateProfileRequest req, IFormFile? avatar)
    {
        if (string.IsNullOrWhiteSpace(req.DisplayName))
        {
            ModelState.AddModelError(nameof(req.DisplayName), "Display name is required.");
            return View(req);
        }
        try
        {
            if (avatar != null && avatar.Length > 0)
            {
                await using var stream = avatar.OpenReadStream();
                var uploaded = await _api.UploadAsync(stream, avatar.FileName, avatar.ContentType);
                req.AvatarUrl = uploaded.Url;
            }
            var updated = await _api.UpdateProfileAsync(req);
            await RefreshCookieAsync(updated);
            TempData["Info"] = "Profile updated.";
            return RedirectToAction(nameof(Index));
        }
        catch (ApiException ex)
        {
            ModelState.AddModelError(string.Empty, ex.Message);
            return View(req);
        }
    }

    private async Task RefreshCookieAsync(UserProfile updated)
    {
        var identity = (ClaimsIdentity)User.Identity!;
        void Replace(string type, string? value)
        {
            var existing = identity.FindFirst(type);
            if (existing != null) identity.RemoveClaim(existing);
            if (!string.IsNullOrEmpty(value)) identity.AddClaim(new Claim(type, value));
        }
        Replace(ClaimTypes.Name, updated.DisplayName);
        Replace("displayName", updated.DisplayName);
        Replace("avatarUrl", updated.AvatarUrl);
        await HttpContext.SignInAsync(CookieAuthenticationDefaults.AuthenticationScheme,
            new ClaimsPrincipal(identity), new AuthenticationProperties { IsPersistent = true });
    }
}
