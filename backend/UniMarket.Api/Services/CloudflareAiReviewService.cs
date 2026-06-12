using System.Net.Http.Json;
using Microsoft.Extensions.Options;
using UniMarket.Api.Configuration;
using UniMarket.Api.DTOs;

namespace UniMarket.Api.Services;

public class CloudflareAiReviewService(
    HttpClient http,
    IOptions<CloudflareSettings> cloudflare,
    IOptions<AdminSettings> admin,
    VerificationQueueService verificationQueue,
    ILogger<CloudflareAiReviewService> logger)
{
    private readonly CloudflareSettings _cloudflare = cloudflare.Value;
    private readonly AdminSettings _admin = admin.Value;

    public bool IsConfigured => _cloudflare.IsAiReviewConfigured && _admin.IsConfigured;

    public async Task TryReviewAsync(string requestId, CancellationToken ct)
    {
        if (!IsConfigured) return;

        try
        {
            var item = await verificationQueue.GetAsync(requestId, ct);
            if (item is null) return;

            using var request = new HttpRequestMessage(HttpMethod.Post, _cloudflare.AiReviewUrl)
            {
                Content = JsonContent.Create(item),
            };
            request.Headers.Add("X-Admin-Key", _admin.ApiKey);

            var response = await http.SendAsync(request, ct);
            if (!response.IsSuccessStatusCode)
            {
                logger.LogWarning(
                    "Cloudflare AI review failed for {RequestId}: {StatusCode}",
                    requestId,
                    response.StatusCode);
                return;
            }

            var review = await response.Content.ReadFromJsonAsync<WorkerAiReviewResponse>(cancellationToken: ct);
            if (review is null || string.IsNullOrWhiteSpace(review.Summary)) return;

            await verificationQueue.SaveAiReviewAsync(
                requestId,
                review.Summary,
                review.Recommendation,
                ct);

            if (!string.Equals(review.Recommendation, "approve", StringComparison.OrdinalIgnoreCase))
            {
                return;
            }

            var current = await verificationQueue.GetAsync(requestId, ct);
            if (current is null ||
                current.Status != "Pending" ||
                current.RequestType != VerificationQueueService.TypeSellerApplication)
            {
                return;
            }

            await verificationQueue.ApproveAsync(requestId, ct);
            logger.LogInformation(
                "Auto-approved seller application {RequestId} after AI review.",
                requestId);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "Cloudflare AI review failed for {RequestId}.", requestId);
        }
    }
}
