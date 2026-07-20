using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MiniSocialNetwork.Web.Models;
using MiniSocialNetwork.Web.Services;

namespace MiniSocialNetwork.Web.Controllers;

public sealed class PostsController : Controller
{
    private readonly ApiClient _api;
    public PostsController(ApiClient api) => _api = api;

    [HttpGet]
    public async Task<IActionResult> Details(Guid id)
    {
        try
        {
            var post = await _api.GetPostAsync(id);
            var comments = await _api.GetCommentsAsync(id);
            return View(new PostDetailsViewModel { Post = post, Comments = comments });
        }
        catch (ApiException)
        {
            return NotFound();
        }
    }

    [Authorize]
    [HttpPost]
    [ValidateAntiForgeryToken]
    [RequestSizeLimit(52_428_800)]
    public async Task<IActionResult> Create(string content, Guid? groupId, IFormFile? media, string? returnUrl)
    {
        if (string.IsNullOrWhiteSpace(content) && (media == null || media.Length == 0))
        {
            TempData["Error"] = "Write something or attach media.";
            return Back(returnUrl, groupId);
        }
        try
        {
            string? mediaUrl = null;
            var mediaType = 0;
            if (media != null && media.Length > 0)
            {
                await using var stream = media.OpenReadStream();
                var uploaded = await _api.UploadAsync(stream, media.FileName, media.ContentType);
                mediaUrl = uploaded.Url;
                mediaType = uploaded.MediaType;
            }
            await _api.CreatePostAsync(new CreatePostRequest
            {
                GroupId = groupId,
                Content = content ?? "",
                MediaUrl = mediaUrl,
                MediaType = mediaType
            });
            TempData["Info"] = "Posted.";
        }
        catch (ApiException ex) { TempData["Error"] = ex.Message; }
        return Back(returnUrl, groupId);
    }

    [Authorize]
    [HttpPost]
    [ValidateAntiForgeryToken]
    [RequestSizeLimit(52_428_800)]
    public async Task<IActionResult> Edit(Guid id, string content, IFormFile? media, bool removeMedia, string? existingMediaUrl, int existingMediaType, string? returnUrl)
    {
        try
        {
            string? mediaUrl = removeMedia ? null : existingMediaUrl;
            var mediaType = removeMedia ? 0 : existingMediaType;
            if (media != null && media.Length > 0)
            {
                await using var stream = media.OpenReadStream();
                var uploaded = await _api.UploadAsync(stream, media.FileName, media.ContentType);
                mediaUrl = uploaded.Url;
                mediaType = uploaded.MediaType;
            }
            await _api.UpdatePostAsync(id, new CreatePostRequest
            {
                Content = content ?? "",
                MediaUrl = mediaUrl,
                MediaType = mediaType
            });
            TempData["Info"] = "Post updated.";
        }
        catch (ApiException ex) { TempData["Error"] = ex.Message; }
        return Back(returnUrl, null);
    }

    [Authorize]
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Delete(Guid id, string? returnUrl)
    {
        try { await _api.DeletePostAsync(id); TempData["Info"] = "Post deleted."; }
        catch (ApiException ex) { TempData["Error"] = ex.Message; }
        return Back(returnUrl, null);
    }

    [Authorize]
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> React(Guid id, int type)
    {
        try
        {
            var summary = await _api.ToggleReactionAsync(id, type);
            return Json(new { ok = true, total = summary.Total, counts = summary.Counts, current = summary.CurrentUserReaction });
        }
        catch (ApiException ex) { return Json(new { ok = false, error = ex.Message }); }
    }

    [HttpGet]
    public async Task<IActionResult> Comments(Guid id)
    {
        try
        {
            var comments = await _api.GetCommentsAsync(id);
            return Json(comments.Select(c => new
            {
                id = c.Id,
                userId = c.UserId,
                authorName = c.AuthorName,
                avatar = UiHelpers.Avatar(c.AuthorAvatarUrl, c.AuthorName),
                content = c.Content,
                createdDate = c.CreatedDate
            }));
        }
        catch (ApiException ex) { return Json(new { ok = false, error = ex.Message }); }
    }

    [Authorize]
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> Comment(Guid id, string content)
    {
        if (string.IsNullOrWhiteSpace(content)) return Json(new { ok = false, error = "Empty comment" });
        try
        {
            var c = await _api.AddCommentAsync(id, content);
            return Json(new
            {
                ok = true,
                comment = new
                {
                    id = c.Id,
                    userId = c.UserId,
                    authorName = c.AuthorName,
                    avatar = UiHelpers.Avatar(c.AuthorAvatarUrl, c.AuthorName),
                    content = c.Content,
                    createdDate = c.CreatedDate
                }
            });
        }
        catch (ApiException ex) { return Json(new { ok = false, error = ex.Message }); }
    }

    [Authorize]
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> EditComment(Guid postId, Guid commentId, string content, string? returnUrl)
    {
        try { await _api.UpdateCommentAsync(postId, commentId, content); }
        catch (ApiException ex) { TempData["Error"] = ex.Message; }
        return Back(returnUrl, null);
    }

    [Authorize]
    [HttpPost]
    [ValidateAntiForgeryToken]
    public async Task<IActionResult> DeleteComment(Guid postId, Guid commentId, string? returnUrl)
    {
        try { await _api.DeleteCommentAsync(postId, commentId); }
        catch (ApiException ex) { TempData["Error"] = ex.Message; }
        return Back(returnUrl, null);
    }

    private IActionResult Back(string? returnUrl, Guid? groupId)
    {
        if (Url.IsLocalUrl(returnUrl)) return Redirect(returnUrl!);
        if (groupId.HasValue) return RedirectToAction("Details", "Groups", new { id = groupId.Value });
        return RedirectToAction("Index", "Home");
    }
}
