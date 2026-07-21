namespace MiniSocialNetwork.Domain.Entities;

public class MarketplaceItem
{
    public Guid Id { get; set; }
    public string SellerId { get; set; } = string.Empty;
    public AppUser Seller { get; set; } = null!;
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string Category { get; set; } = string.Empty;
    public string Condition { get; set; } = string.Empty;
    public string? MediaUrl { get; set; }
    public int Status { get; set; }
    public DateTime CreatedDate { get; set; }
    public DateTime? UpdatedDate { get; set; }
}
