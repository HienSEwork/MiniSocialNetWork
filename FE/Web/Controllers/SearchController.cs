using Microsoft.AspNetCore.Mvc;
using MiniSocialNetwork.Web.Models;
using MiniSocialNetwork.Web.Services;

namespace MiniSocialNetwork.Web.Controllers;

public sealed class SearchController : Controller
{
    private readonly ApiClient _api;
    public SearchController(ApiClient api) => _api = api;

    [HttpGet]
    public async Task<IActionResult> Index(string? q)
    {
        var result = new SearchResponse { Query = q ?? "" };
        if (!string.IsNullOrWhiteSpace(q))
        {
            try { result = await _api.SearchAsync(q, 15); } catch (ApiException) { }
        }
        return View(result);
    }
}
