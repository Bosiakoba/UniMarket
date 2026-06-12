namespace UniMarket.Api.Services;

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
                logger.LogWarning(ex, "Background AI review failed for {RequestId}.", requestId);
            }
        });
    }
}
