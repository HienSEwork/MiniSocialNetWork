using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MiniSocialNetwork.Web.Models;
using MiniSocialNetwork.Web.Services;

namespace MiniSocialNetwork.Web.Controllers;

[Authorize]
public sealed class ChatController : Controller
{
    private readonly ApiClient _api;
    public ChatController(ApiClient api) => _api = api;

    [HttpGet]
    public async Task<IActionResult> Index()
    {
        var vm = new ChatViewModel
        {
            HubUrl = _api.BaseUrl + "/hubs/chat",
            Token = User.FindFirst("jwt")?.Value ?? ""
        };
        try { vm.Users = await _api.GetChatUsersAsync(); } catch (ApiException) { }
        try { vm.Groups = await _api.GetMyGroupsAsync(); } catch (ApiException) { }
        return View(vm);
    }

    [HttpGet]
    public async Task<IActionResult> Users(string? keyword)
    {
        try
        {
            var users = await _api.GetChatUsersAsync(keyword);
            return Json(users.Select(u => new { id = u.Id, name = u.DisplayName, avatar = UiHelpers.Avatar(u.AvatarUrl, u.DisplayName) }));
        }
        catch (ApiException ex) { return Json(new { ok = false, error = ex.Message }); }
    }

    [HttpGet]
    public async Task<IActionResult> PrivateHistory(string otherUserId)
    {
        try { return Json(await _api.GetPrivateHistoryAsync(otherUserId)); }
        catch (ApiException ex) { return Json(new { ok = false, error = ex.Message }); }
    }

    [HttpGet]
    public async Task<IActionResult> GroupHistory(Guid groupId)
    {
        try { return Json(await _api.GetGroupHistoryAsync(groupId)); }
        catch (ApiException ex) { return Json(new { ok = false, error = ex.Message }); }
    }

    [HttpPost, ValidateAntiForgeryToken]
    public async Task<IActionResult> Send(string? receiverId, Guid? groupId, string content)
    {
        if (string.IsNullOrWhiteSpace(content)) return Json(new { ok = false, error = "Empty message" });
        try
        {
            var msg = await _api.SendMessageAsync(new SendMessageRequest { ReceiverId = receiverId, GroupId = groupId, Content = content });
            return Json(new { ok = true, message = msg });
        }
        catch (ApiException ex) { return Json(new { ok = false, error = ex.Message }); }
    }
}
