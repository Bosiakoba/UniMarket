namespace UniMarket.Api.Services;

/// <summary>
/// Runs AI review outside the HTTP request so proxy/client disconnects cannot cancel it.
/// </summary>
public class AiReviewBackgroundDispatcher(
    IServiceScopeFactory scopeFactory,
    ILogger<AiReviewBackgroundDispatcher> logger)
{
    public void Enqueue(string requestId)
    {
        _ = Task.Run(async () =>
        {
            try
            {
                await using var scope = scopeFactory.CreateAsyncScope();
                var review = scope.ServiceProvider.GetRequiredService<CloudflareAiReviewService>();
                await review.TryReviewAsync(requestId, CancellationToken.None);
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Background AI review failed for {RequestId}.", requestId);
            }
        });
    }
}
