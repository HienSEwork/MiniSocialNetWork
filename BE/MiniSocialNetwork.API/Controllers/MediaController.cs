using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MiniSocialNetwork.API.Controllers;

[Authorize]
[ApiController]
[Route("api/media")]
public sealed class MediaController : ControllerBase
{
    private static readonly HashSet<string> VideoExtensions =
        new(StringComparer.OrdinalIgnoreCase) { ".mp4", ".mov", ".webm", ".m4v", ".ogv" };
    private static readonly HashSet<string> ImageExtensions =
        new(StringComparer.OrdinalIgnoreCase)
        { ".jpg", ".jpeg", ".jfif", ".pjpeg", ".pjp", ".png", ".webp", ".gif", ".bmp", ".avif", ".heic", ".heif" };

    private static readonly Dictionary<string, string> ContentTypeExtensions =
        new(StringComparer.OrdinalIgnoreCase)
        {
            ["image/jpeg"] = ".jpg", ["image/pjpeg"] = ".jpg", ["image/png"] = ".png",
            ["image/webp"] = ".webp", ["image/gif"] = ".gif", ["image/bmp"] = ".bmp",
            ["image/avif"] = ".avif", ["image/heic"] = ".heic", ["image/heif"] = ".heif",
            ["video/mp4"] = ".mp4", ["video/quicktime"] = ".mov", ["video/webm"] = ".webm",
        };

    private readonly IWebHostEnvironment _environment;

    public MediaController(IWebHostEnvironment environment) => _environment = environment;

    [HttpPost("upload")]
    [RequestSizeLimit(52_428_800)]
    public async Task<IActionResult> Upload(IFormFile file)
    {
        if (file.Length == 0) throw new ArgumentException("File is empty");
        if (file.Length > 52_428_800) throw new ArgumentException("File exceeds the 50 MB limit");

        var extension = ResolveExtension(file);
        if (extension == null) throw new ArgumentException("File type is not supported");

        var folder = Path.Combine(_environment.WebRootPath ?? Path.Combine(_environment.ContentRootPath, "wwwroot"), "uploads");
        Directory.CreateDirectory(folder);
        var fileName = $"{Guid.NewGuid():N}{extension}";
        await using var stream = System.IO.File.Create(Path.Combine(folder, fileName));
        await file.CopyToAsync(stream);
        var url = $"{Request.Scheme}://{Request.Host}/uploads/{fileName}";
        var mediaType = VideoExtensions.Contains(extension) ? 2 : 1;
        return Ok(new { url, mediaType });
    }

    // Prefer the file extension; fall back to the browser-provided content type so images
    // saved without a usable extension (e.g. .jfif from Chrome, HEIC from iPhone) still work.
    private static string? ResolveExtension(IFormFile file)
    {
        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (ImageExtensions.Contains(extension) || VideoExtensions.Contains(extension))
            return extension;
        if (ContentTypeExtensions.TryGetValue(file.ContentType?.Split(';')[0].Trim() ?? "", out var mapped))
            return mapped;
        return null;
    }
}
