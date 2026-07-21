using MiniSocialNetwork.Domain.Entities;

namespace MiniSocialNetwork.Application.Interfaces.Repositories;

public interface ISearchRepository
{
    Task<SearchRepositoryResult> SearchAsync(string query, int limit);
}

public sealed class SearchRepositoryResult
{
    public int UserTotal { get; init; }
    public int GroupTotal { get; init; }
    public int PostTotal { get; init; }
    public IReadOnlyCollection<AppUser> Users { get; init; } = Array.Empty<AppUser>();
    public IReadOnlyCollection<Group> Groups { get; init; } = Array.Empty<Group>();
    public IReadOnlyCollection<Post> Posts { get; init; } = Array.Empty<Post>();
}
