using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Options;
using UniMarket.Api.Configuration;

namespace UniMarket.Api.Services;

public class CloudflareAiReviewService(
    HttpClient http,
    IOptions<CloudflareSettings> cloudflare,
    IOptions<AdminSettings> admin,
    ILogger<CloudflareAiReviewService> logger)
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
    };

    private readonly CloudflareSettings _cloudflare = cloudflare.Value;
    private readonly AdminSettings _admin = admin.Value;

    public bool IsConfigured => _cloudflare.IsAiReviewConfigured && _admin.IsConfigured;

    public async Task TryReviewAsync(string requestId, CancellationToken ct)
    {
        if (!IsConfigured)
        {
            logger.LogWarning(
                "AI review skipped for {RequestId}. Set Admin__ApiKey and Cloudflare__AiReviewUrl in API .env.",
                requestId);
            return;
        }

        var processUrl = ResolveProcessRequestUrl(_cloudflare.AiReviewUrl);
        if (processUrl is null)
        {
            logger.LogWarning(
                "AI review skipped for {RequestId}. Cloudflare__AiReviewUrl must end with /api/ai-review.",
                requestId);
            return;
        }

        try
        {
            logger.LogInformation(
                "Starting Cloudflare AI review for {RequestId}.",
                requestId);

            using var request = new HttpRequestMessage(HttpMethod.Post, processUrl)
            {
                Content = JsonContent.Create(new { requestId }),
            };
            request.Headers.Add("X-Admin-Key", _admin.ApiKey);

            var response = await http.SendAsync(request, ct);
            if (!response.IsSuccessStatusCode)
            {
                var body = await response.Content.ReadAsStringAsync(ct);
                logger.LogWarning(
                    "Cloudflare AI review failed for {RequestId}: {StatusCode} {Body}",
                    requestId,
                    response.StatusCode,
                    body);
                return;
            }

            var result = await response.Content.ReadFromJsonAsync<WorkerProcessResponse>(
                JsonOptions,
                cancellationToken: ct);
            if (result?.Ok == true)
            {
                logger.LogInformation(
                    "Cloudflare AI review completed for {RequestId} (skipped={Skipped}).",
                    requestId,
                    result.Skipped);
            }
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Cloudflare AI review failed for {RequestId}.", requestId);
        }
    }

    private static string? ResolveProcessRequestUrl(string aiReviewUrl)
    {
        var trimmed = aiReviewUrl.Trim();
        if (!trimmed.EndsWith("/api/ai-review", StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        return trimmed[..^"/api/ai-review".Length] + "/api/process-request";
    }

    private sealed record WorkerProcessResponse(bool Ok, bool Skipped);
}
