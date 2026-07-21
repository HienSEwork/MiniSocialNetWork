using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MiniSocialNetwork.API.Controllers;

[Authorize]
[ApiController]
[Route("api/media")]
public sealed class MediaController : ControllerBase
{
    private static readonly HashSet<string> AllowedExtensions =
        new(StringComparer.OrdinalIgnoreCase) { ".jpg", ".jpeg", ".png", ".webp", ".gif", ".mp4", ".mov", ".webm" };
    private readonly IWebHostEnvironment _environment;

    public MediaController(IWebHostEnvironment environment) => _environment = environment;

    [HttpPost("upload")]
    [RequestSizeLimit(52_428_800)]
    public async Task<IActionResult> Upload(IFormFile file)
    {
        if (file.Length == 0) throw new ArgumentException("File is empty");
        if (file.Length > 52_428_800) throw new ArgumentException("File exceeds the 50 MB limit");
        var extension = Path.GetExtension(file.FileName);
        if (!AllowedExtensions.Contains(extension)) throw new ArgumentException("File type is not supported");

        var folder = Path.Combine(_environment.WebRootPath ?? Path.Combine(_environment.ContentRootPath, "wwwroot"), "uploads");
        Directory.CreateDirectory(folder);
        var fileName = $"{Guid.NewGuid():N}{extension.ToLowerInvariant()}";
        await using var stream = System.IO.File.Create(Path.Combine(folder, fileName));
        await file.CopyToAsync(stream);
        var url = $"{Request.Scheme}://{Request.Host}/uploads/{fileName}";
        var mediaType = new[] { ".mp4", ".mov", ".webm" }.Contains(extension.ToLowerInvariant()) ? 2 : 1;
        return Ok(new { url, mediaType });
    }
}
