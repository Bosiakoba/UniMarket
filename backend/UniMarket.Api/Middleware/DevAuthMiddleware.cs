using System.Security.Claims;
using UniMarket.Api.Services;

namespace UniMarket.Api.Middleware;

/// <summary>
/// Temporary auth until Firebase Admin SDK is wired.
/// Accepts X-Dev-User-Id or an authenticated ClaimsPrincipal (future Firebase).
/// </summary>
public class DevAuthMiddleware(RequestDelegate next)
{
    public async Task InvokeAsync(HttpContext context, CurrentUserService currentUser)
    {
        if (context.User.Identity?.IsAuthenticated == true)
        {
            var uid = context.User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? context.User.FindFirstValue("user_id");
            if (!string.IsNullOrWhiteSpace(uid))
            {
                context.Items["UserId"] = uid;
            }
        }
        else if (context.Request.Headers.TryGetValue(CurrentUserService.DevUserHeader, out var devId)
                 && !string.IsNullOrWhiteSpace(devId))
        {
            context.Items["UserId"] = devId.ToString();
        }

        await next(context);
    }
}
