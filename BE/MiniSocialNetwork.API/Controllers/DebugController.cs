using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Routing;

namespace MiniSocialNetwork.API.Controllers;

[ApiController]
[Route("api/debug")]
public sealed class DebugController : ControllerBase
{
    private readonly EndpointDataSource _source;

    public DebugController(EndpointDataSource source)
    {
        _source = source;
    }

    [HttpGet("endpoints")]
    public ActionResult<IEnumerable<string>> GetEndpoints()
    {
        return Ok(_source.Endpoints.Select(e => e.DisplayName ?? e.ToString()));
    }
}
