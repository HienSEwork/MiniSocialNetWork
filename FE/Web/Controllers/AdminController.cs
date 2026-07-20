using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MiniSocialNetwork.Web.Models;
using MiniSocialNetwork.Web.Services;

namespace MiniSocialNetwork.Web.Controllers;

[Authorize(Roles = "Admin")]
public sealed class AdminController : Controller
{
    private readonly ApiClient _api;
    public AdminController(ApiClient api) => _api = api;

    [HttpGet]
    public async Task<IActionResult> Index(string? keyword, int page = 1)
    {
        var vm = new AdminViewModel { Keyword = keyword };
        try { vm.Stats = await _api.GetStatsAsync(); } catch (ApiException) { }
        try { vm.PostsPerDay = await _api.GetPostsPerDayAsync(14); } catch (ApiException) { }
        try { vm.Users = await _api.GetUsersAsync(keyword, page, 10); } catch (ApiException) { }
        return View(vm);
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteUser(string id, string? keyword)
    {
        try { await _api.DeleteUserAsync(id); TempData["Info"] = "User deleted."; }
        catch (ApiException ex) { TempData["Error"] = ex.Message; }
        return RedirectToAction(nameof(Index), new { keyword });
    }
}
