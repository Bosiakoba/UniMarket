using Microsoft.AspNetCore.SignalR;
using UniMarket.Api.Hubs;

namespace UniMarket.Api.Services;

/// <summary>
/// Periodically clears stale presence entries (users whose connections died
/// without a clean disconnect, e.g. a mobile app being killed or a network drop)
/// and broadcasts their offline transition so other clients update in real time.
/// </summary>
public class PresenceCleanupService(
    UserPresenceStore presenceStore,
    IHubContext<ChatHub> chatHub,
    ILogger<PresenceCleanupService> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(TimeSpan.FromSeconds(60));

        while (await timer.WaitForNextTickAsync(stoppingToken))
        {
            try
            {
                var removed = presenceStore.CleanupStale();
                if (removed.Count == 0)
                {
                    continue;
                }

                foreach (var (userId, lastSeenAt) in removed)
                {
                    logger.LogInformation("Cleaned stale presence for user {UserId}", userId);
                    await chatHub.Clients.All.SendAsync("UserPresenceChanged", new
                    {
                        userId,
                        isOnline = false,
                        lastSeenAt,
                    }, stoppingToken);
                }
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Presence cleanup failed");
            }
        }
    }
}
