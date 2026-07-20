namespace MiniSocialNetwork.Application.DTOs.Admin;

public class UserQuery
{
    public string? Keyword { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 10;
}
