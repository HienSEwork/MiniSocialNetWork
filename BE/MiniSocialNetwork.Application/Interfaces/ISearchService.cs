using MiniSocialNetwork.Application.DTOs.Search;

namespace MiniSocialNetwork.Application.Interfaces;

public interface ISearchService
{
    Task<SearchResponse> SearchAsync(string? query, int limit = 10);
}
