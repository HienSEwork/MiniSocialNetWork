using System.Net;
using System.Text.Json;
using System.Security.Authentication;

using MiniSocialNetwork.Application.Exceptions;

namespace MiniSocialNetwork.API.Middlewares;

public class ExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionMiddleware> _logger;

    public ExceptionMiddleware(RequestDelegate next, ILogger<ExceptionMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            var status = GetStatusCode(ex);
            if (status == HttpStatusCode.InternalServerError)
                _logger.LogError(ex, "Unhandled exception");
            else
                _logger.LogWarning("Request failed with status {StatusCode}: {Message}", (int)status, ex.Message);

            await HandleAsync(context, ex, status);
        }
    }

    private static HttpStatusCode GetStatusCode(Exception ex)
    {
        return ex switch
        {
            AuthenticationException => HttpStatusCode.Unauthorized,
            KeyNotFoundException => HttpStatusCode.NotFound,
            UnauthorizedAccessException => HttpStatusCode.Forbidden,
            ConflictException => HttpStatusCode.Conflict,
            ArgumentException => HttpStatusCode.BadRequest,
            InvalidOperationException => HttpStatusCode.BadRequest,
            _ => HttpStatusCode.InternalServerError
        };
    }

    private static Task HandleAsync(HttpContext context, Exception ex, HttpStatusCode status)
    {
        var payload = new ApiResponse<object?>
        {
            Success = false,
            Message = ex.Message,
            Data = null
        };

        context.Response.ContentType = "application/json";
        context.Response.StatusCode = (int)status;

        var json = JsonSerializer.Serialize(payload,
            new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase });

        return context.Response.WriteAsync(json);
    }
}
