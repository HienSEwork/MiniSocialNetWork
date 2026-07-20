using Microsoft.AspNetCore.Mvc;
using MiniSocialNetwork.Web.Services;

namespace MiniSocialNetwork.Web.Controllers;

public sealed class LangController : Controller
{
    [HttpGet]
    public IActionResult Set(string culture, string? returnUrl)
    {
        var value = culture == "en" ? "en" : "vi";
        Response.Cookies.Append(Loc.CookieName, value, new CookieOptions
        {
            Expires = DateTimeOffset.UtcNow.AddYears(1),
            IsEssential = true,
            HttpOnly = false
        });
        return Url.IsLocalUrl(returnUrl) ? Redirect(returnUrl!) : RedirectToAction("Index", "Home");
    }
}
