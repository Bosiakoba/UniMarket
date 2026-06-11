using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using UniMarket.Api.Configuration;
using UniMarket.Api.Data;
using UniMarket.Api.Services;

namespace UniMarket.Api.Middleware;

/// <summary>
/// Resolves the app user id from a Firebase Bearer token (production) or
/// X-Dev-User-Id header when Firebase is disabled (local demo).
/// </summary>
public class AuthMiddleware(
    RequestDelegate next,
    FirebaseAuthService firebaseAuth,
    IOptions<FirebaseSettings> firebaseSettings)
{
    public async Task InvokeAsync(
        HttpContext context,
        AppDbContext db)
    {
        if (firebaseAuth.IsActive &&
            TryReadBearerToken(context, out var idToken))
        {
            try
            {
                var decoded = await firebaseAuth.VerifyIdTokenAsync(
                    idToken,
                    context.RequestAborted);
                var user = await db.Users
                    .AsNoTracking()
                    .FirstOrDefaultAsync(
                        u => u.FirebaseUid == decoded.Uid,
                        context.RequestAborted);

                if (user is not null)
                {
                    context.Items["UserId"] = user.Id;
                }
            }
            catch
            {
                // Leave unauthenticated — protected endpoints return 401.
            }
        }
        else if (!firebaseSettings.Value.Enabled &&
                 context.Request.Headers.TryGetValue(
                     CurrentUserService.DevUserHeader,
                     out var devId) &&
                 !string.IsNullOrWhiteSpace(devId))
        {
            context.Items["UserId"] = devId.ToString();
        }

        await next(context);
    }

    private static bool TryReadBearerToken(HttpContext context, out string token)
    {
        token = string.Empty;
        if (!context.Request.Headers.TryGetValue("Authorization", out var header))
        {
            return false;
        }

        var value = header.ToString();
        const string prefix = "Bearer ";
        if (!value.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
        {
            return false;
        }

        token = value[prefix.Length..].Trim();
        return token.Length > 0;
    }
}
