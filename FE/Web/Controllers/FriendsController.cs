using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MiniSocialNetwork.Web.Models;
using MiniSocialNetwork.Web.Services;

namespace MiniSocialNetwork.Web.Controllers;

[Authorize]
public sealed class FriendsController : Controller
{
    private readonly ApiClient _api;

    public FriendsController(ApiClient api) => _api = api;

    // GET /Friends
    [HttpGet]
    public async Task<IActionResult> Index(string? q)
    {
        var friends = await _api.GetFriendsAsync();
        List<FriendSearchDto>? searchResults = null;
        if (!string.IsNullOrWhiteSpace(q))
            searchResults = await _api.SearchUsersForFriendsAsync(q);

        ViewData["Query"] = q ?? string.Empty;
        return View(new FriendsIndexViewModel
        {
            Friends = friends,
            SearchResults = searchResults ?? new List<FriendSearchDto>()
        });
    }

    // POST /Friends/Send
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Send(string id)
    {
        if (string.IsNullOrWhiteSpace(id)) return RedirectToAction(nameof(Index));

        try
        {
            var reqId = await _api.SendFriendRequestAsync(id);
            TempData["Info"] = "Đã gửi lời mời kết bạn";
        }
        catch (Exception ex)
        {
            TempData["Error"] = ex.Message;
        }

        return RedirectToAction(nameof(Index));
    }

    // POST /Friends/Remove
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Remove(string id)
    {
        if (string.IsNullOrWhiteSpace(id)) return RedirectToAction(nameof(Index));

        try
        {
            await _api.DeleteFriendAsync(id);
            TempData["Info"] = "Đã hủy kết bạn";
        }
        catch (Exception ex)
        {
            TempData["Error"] = ex.Message;
        }

        return RedirectToAction(nameof(Index));
    }

    // GET /Friends/Requests
    [HttpGet]
    public async Task<IActionResult> Requests()
    {
        var items = await _api.GetIncomingFriendRequestsAsync();
        return View(items);
    }

    // POST /Friends/Respond
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Respond(Guid requestId, bool accept)
    {
        try
        {
            await _api.RespondFriendRequestAsync(requestId, accept);
            TempData["Info"] = accept ? "Đã chấp nhận lời mời" : "Đã từ chối lời mời";
        }
        catch (Exception ex)
        {
            TempData["Error"] = ex.Message;
        }
        return RedirectToAction(nameof(Requests));
    }
}