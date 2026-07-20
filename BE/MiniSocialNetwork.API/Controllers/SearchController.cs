using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MiniSocialNetwork.Application.DTOs.Search;
using MiniSocialNetwork.Application.Interfaces;

namespace MiniSocialNetwork.API.Controllers;

[ApiController]
[Route("api/search")]
public sealed class SearchController : ControllerBase
{
    private readonly ISearchService _searchService;

    public SearchController(ISearchService searchService)
    {
        _searchService = searchService;
    }

    [AllowAnonymous]
    [HttpGet]
    public async Task<ActionResult<SearchResponse>> Search(
        [FromQuery(Name = "q")] string? query,
        [FromQuery] int limit = 10)
        => Ok(await _searchService.SearchAsync(query, limit));
}
