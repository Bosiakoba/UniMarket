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
    private const int MaxAttempts = 3;
    private static readonly TimeSpan RetryDelay = TimeSpan.FromSeconds(2);

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
    };

    private readonly CloudflareSettings _cloudflare = cloudflare.Value;
    private readonly AdminSettings _admin = admin.Value;

    public bool IsConfigured => _cloudflare.IsAiReviewConfigured && _admin.IsConfigured;

    public async Task<bool> TryReviewAsync(string requestId, CancellationToken ct)
    {
        if (!IsConfigured)
        {
            logger.LogWarning(
                "AI review skipped for {RequestId}. Set Admin__ApiKey and Cloudflare__AiReviewUrl in API .env.",
                requestId);
            return false;
        }

        var processUrl = ResolveProcessRequestUrl(_cloudflare.AiReviewUrl);
        if (processUrl is null)
        {
            logger.LogWarning(
                "AI review skipped for {RequestId}. Cloudflare__AiReviewUrl must end with /api/ai-review.",
                requestId);
            return false;
        }

        for (var attempt = 1; attempt <= MaxAttempts; attempt++)
        {
            try
            {
                logger.LogInformation(
                    "Starting Cloudflare AI review for {RequestId} (attempt {Attempt}/{MaxAttempts}).",
                    requestId,
                    attempt,
                    MaxAttempts);

                using var request = new HttpRequestMessage(HttpMethod.Post, processUrl)
                {
                    Content = JsonContent.Create(new { requestId }),
                };
                request.Headers.Add("X-Admin-Key", _admin.ApiKey);

                using var response = await http.SendAsync(request, ct);
                var body = await response.Content.ReadAsStringAsync(ct);
                if (!response.IsSuccessStatusCode)
                {
                    logger.LogWarning(
                        "Cloudflare AI review failed for {RequestId} on attempt {Attempt}: {StatusCode} {Body}",
                        requestId,
                        attempt,
                        response.StatusCode,
                        body);

                    if (attempt < MaxAttempts)
                    {
                        await Task.Delay(RetryDelay, ct);
                        continue;
                    }

                    return false;
                }

                var result = JsonSerializer.Deserialize<WorkerProcessResponse>(body, JsonOptions);
                if (result?.Ok == true)
                {
                    logger.LogInformation(
                        "Cloudflare AI review completed for {RequestId} (skipped={Skipped}).",
                        requestId,
                        result.Skipped);
                    return true;
                }

                logger.LogWarning(
                    "Cloudflare AI review returned unexpected payload for {RequestId}: {Body}",
                    requestId,
                    body);
            }
            catch (Exception ex) when (attempt < MaxAttempts)
            {
                logger.LogWarning(
                    ex,
                    "Cloudflare AI review attempt {Attempt} failed for {RequestId}; retrying.",
                    attempt,
                    requestId);
                await Task.Delay(RetryDelay, ct);
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Cloudflare AI review failed for {RequestId}.", requestId);
                return false;
            }
        }

        return false;
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
