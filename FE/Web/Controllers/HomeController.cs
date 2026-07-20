using System.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using MiniSocialNetwork.Web.Models;
using MiniSocialNetwork.Web.Services;

namespace MiniSocialNetwork.Web.Controllers;

public sealed class HomeController : Controller
{
    private readonly ApiClient _api;
    public HomeController(ApiClient api) => _api = api;

    public async Task<IActionResult> Index(int page = 1)
    {
        var vm = new FeedViewModel { Page = page < 1 ? 1 : page };
        try
        {
            vm.Feed = await _api.GetFeedAsync(vm.Page, 10);
        }
        catch (Exception ex) when (IsApiDown(ex))
        {
            TempData["Error"] = Loc.T(HttpContext, "feed.loadError");
        }

        if (User.Identity?.IsAuthenticated == true)
        {
            try { vm.MyGroups = await _api.GetMyGroupsAsync(); } catch (Exception ex) when (IsApiDown(ex)) { }
            var myIds = vm.MyGroups.Select(g => g.Id).ToHashSet();
            try
            {
                var all = await _api.GetGroupsAsync();
                vm.SuggestedGroups = all.Where(g => !myIds.Contains(g.Id)).Take(5).ToList();
            }
            catch (Exception ex) when (IsApiDown(ex)) { }
        }
        else
        {
            try { vm.SuggestedGroups = (await _api.GetGroupsAsync()).Take(5).ToList(); } catch (Exception ex) when (IsApiDown(ex)) { }
        }

        return View(vm);
    }

    private static bool IsApiDown(Exception ex) =>
        ex is ApiException or HttpRequestException or TaskCanceledException;

    [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
    public IActionResult Error()
        => View(new ErrorViewModel { RequestId = Activity.Current?.Id ?? HttpContext.TraceIdentifier });
}
