using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using MiniSocialNetwork.Application.DTOs.Marketplace;
using MiniSocialNetwork.Domain.Entities;
using MiniSocialNetwork.Infrastructure.Persistence;

namespace MiniSocialNetwork.API.Controllers;

[Authorize]
[ApiController]
[Route("api/marketplace")]
public sealed class MarketplaceController : ControllerBase
{
    private const int ActiveLimit = 5;
    private readonly AppDbContext _context;

    public MarketplaceController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<ActionResult<IReadOnlyCollection<MarketplaceItemResponse>>> GetAll(
        [FromQuery] string? keyword,
        [FromQuery] string? category)
    {
        var query = _context.MarketplaceItems
            .Include(item => item.Seller)
            .Where(item => item.Status != 2);
        if (!string.IsNullOrWhiteSpace(keyword))
            query = query.Where(item => item.Title.Contains(keyword) || item.Description.Contains(keyword));
        if (!string.IsNullOrWhiteSpace(category))
            query = query.Where(item => item.Category == category.Trim());
        var items = await query
            .OrderBy(item => item.Status)
            .ThenByDescending(item => item.CreatedDate)
            .Take(80)
            .ToListAsync();
        return Ok(items.Select(Map).ToArray());
    }

    [HttpGet("mine")]
    public async Task<ActionResult<IReadOnlyCollection<MarketplaceItemResponse>>> Mine()
        => Ok(await SellerItemsAsync(CurrentUserId));

    [HttpGet("seller/{sellerId}")]
    public async Task<ActionResult<IReadOnlyCollection<MarketplaceItemResponse>>> Seller(string sellerId)
        => Ok(await SellerItemsAsync(sellerId));

    [HttpGet("mine/stats")]
    public async Task<ActionResult<MarketplaceSellerStatsResponse>> MyStats()
        => Ok(await StatsAsync(CurrentUserId));

    [HttpGet("seller/{sellerId}/stats")]
    public async Task<ActionResult<MarketplaceSellerStatsResponse>> SellerStats(string sellerId)
        => Ok(await StatsAsync(sellerId));

    [HttpPost]
    public async Task<IActionResult> Create(MarketplaceItemRequest request)
    {
        Validate(request);
        var activeCount = await _context.MarketplaceItems.CountAsync(item =>
            item.SellerId == CurrentUserId && item.Status == 0);
        if (activeCount >= ActiveLimit)
            throw new InvalidOperationException("Bạn chỉ được đăng tối đa 5 sản phẩm đang bán.");

        var item = new MarketplaceItem
        {
            Id = Guid.NewGuid(),
            SellerId = CurrentUserId,
            Title = request.Title.Trim(),
            Description = request.Description.Trim(),
            Price = request.Price,
            Category = Normalize(request.Category, "Khác"),
            Condition = Normalize(request.Condition, "Đã sử dụng"),
            MediaUrl = EmptyToNull(request.MediaUrl),
            Status = 0,
            CreatedDate = DateTime.UtcNow
        };
        await _context.MarketplaceItems.AddAsync(item);
        await _context.SaveChangesAsync();
        return CreatedAtAction(nameof(Mine), new { id = item.Id }, new { item.Id });
    }

    [HttpPut("{id:guid}")]
    public async Task<IActionResult> Update(Guid id, MarketplaceItemRequest request)
    {
        Validate(request);
        var item = await GetOwnedItemAsync(id);
        item.Title = request.Title.Trim();
        item.Description = request.Description.Trim();
        item.Price = request.Price;
        item.Category = Normalize(request.Category, "Khác");
        item.Condition = Normalize(request.Condition, "Đã sử dụng");
        item.MediaUrl = EmptyToNull(request.MediaUrl);
        item.UpdatedDate = DateTime.UtcNow;
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpPost("{id:guid}/mark-sold")]
    public async Task<IActionResult> MarkSold(Guid id)
    {
        var item = await GetOwnedItemAsync(id);
        item.Status = 1;
        item.UpdatedDate = DateTime.UtcNow;
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpPost("{id:guid}/relist")]
    public async Task<IActionResult> Relist(Guid id)
    {
        var activeCount = await _context.MarketplaceItems.CountAsync(item =>
            item.SellerId == CurrentUserId && item.Status == 0);
        if (activeCount >= ActiveLimit)
            throw new InvalidOperationException("Bạn chỉ được đăng tối đa 5 sản phẩm đang bán.");
        var item = await GetOwnedItemAsync(id);
        item.Status = 0;
        item.UpdatedDate = DateTime.UtcNow;
        await _context.SaveChangesAsync();
        return NoContent();
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        var item = await GetOwnedItemAsync(id);
        item.Status = 2;
        item.UpdatedDate = DateTime.UtcNow;
        await _context.SaveChangesAsync();
        return NoContent();
    }

    private async Task<IReadOnlyCollection<MarketplaceItemResponse>> SellerItemsAsync(string sellerId)
    {
        var items = await _context.MarketplaceItems
            .Include(item => item.Seller)
            .Where(item => item.SellerId == sellerId && item.Status != 2)
            .OrderBy(item => item.Status)
            .ThenByDescending(item => item.CreatedDate)
            .Take(20)
            .ToListAsync();
        return items.Select(Map).ToArray();
    }

    private async Task<MarketplaceSellerStatsResponse> StatsAsync(string sellerId)
        => new()
        {
            SellerId = sellerId,
            ActiveCount = await _context.MarketplaceItems.CountAsync(item => item.SellerId == sellerId && item.Status == 0),
            SoldCount = await _context.MarketplaceItems.CountAsync(item => item.SellerId == sellerId && item.Status == 1),
            Limit = ActiveLimit
        };

    private async Task<MarketplaceItem> GetOwnedItemAsync(Guid id)
    {
        var item = await _context.MarketplaceItems.FirstOrDefaultAsync(item => item.Id == id && item.Status != 2);
        if (item == null) throw new KeyNotFoundException("Product not found");
        if (item.SellerId != CurrentUserId) throw new UnauthorizedAccessException("Only the seller can modify this product");
        return item;
    }

    private static void Validate(MarketplaceItemRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Title)) throw new ArgumentException("Tên sản phẩm là bắt buộc");
        if (request.Title.Length > 120) throw new ArgumentException("Tên sản phẩm quá dài");
        if (request.Price < 0) throw new ArgumentException("Giá sản phẩm không hợp lệ");
        if (request.Description.Length > 2000) throw new ArgumentException("Mô tả sản phẩm quá dài");
    }

    private static MarketplaceItemResponse Map(MarketplaceItem item) => new()
    {
        Id = item.Id,
        SellerId = item.SellerId,
        SellerName = item.Seller?.DisplayName ?? "Member",
        SellerAvatarUrl = item.Seller?.AvatarUrl,
        Title = item.Title,
        Description = item.Description,
        Price = item.Price,
        Category = item.Category,
        Condition = item.Condition,
        MediaUrl = item.MediaUrl,
        Status = item.Status,
        CreatedDate = item.CreatedDate,
        UpdatedDate = item.UpdatedDate
    };

    private static string Normalize(string value, string fallback)
        => string.IsNullOrWhiteSpace(value) ? fallback : value.Trim();

    private static string? EmptyToNull(string? value)
        => string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private string CurrentUserId => User.FindFirstValue(ClaimTypes.NameIdentifier)!;
}
