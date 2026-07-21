using System.Globalization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Localization;

namespace MiniSocialNetwork.API.Controllers;

[ApiController]
[Route("api/localization")]
public class LocalizationController : ControllerBase
{
    private readonly IStringLocalizer<SharedResource> _localizer;

    public LocalizationController(IStringLocalizer<SharedResource> localizer)
    {
        _localizer = localizer;
    }

    // Try: GET /api/localization/greeting?culture=en  vs  ?culture=vi
    [HttpGet("greeting")]
    public IActionResult Greeting()
    {
        return Ok(new
        {
            culture = CultureInfo.CurrentCulture.Name,
            welcome = _localizer["Welcome"].Value,
            hello = _localizer["Hello"].Value,
            language = _localizer["Language"].Value
        });
    }
}
