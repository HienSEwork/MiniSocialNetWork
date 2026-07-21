namespace MiniSocialNetwork.Application.DTOs.Group;
public class GroupQuery
{
    public string? Keyword { get; set; }
    public string? OwnerId { get; set; }

    public int? MinMembers { get; set; }
    public int? MaxMembers { get; set; }

    public DateTime? CreatedFrom { get; set; }
    public DateTime? CreatedTo { get; set; }

    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 10;
}