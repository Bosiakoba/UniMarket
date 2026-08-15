namespace UniMarket.Api.Services;

public class CurrentUserService(IHttpContextAccessor httpContextAccessor)
{
    public const string DevUserHeader = "X-Dev-User-Id";

    public string? UserId =>
        httpContextAccessor.HttpContext?.Items["UserId"] as string;

    public bool IsAuthenticated => !string.IsNullOrWhiteSpace(UserId);
}
