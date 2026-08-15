using Microsoft.AspNetCore.SignalR;
using UniMarket.Api.Services;

namespace UniMarket.Api.Hubs;

/// <summary>
/// SignalR hub for delivering chat messages in real-time to connected clients.
/// Each user is placed into a personal group ("user_{userId}") so we can
/// target messages to the correct recipient without broadcasting to everyone.
/// Also tracks online presence so clients can show real-time online/offline status.
/// </summary>
/// <remarks>
/// Presence is tracked entirely in-memory via <see cref="UserPresenceStore"/>.
/// No DB columns are needed; this avoids migration issues on existing deployments.
/// </remarks>
public class ChatHub(
    CurrentUserService currentUser,
    UserPresenceStore presenceStore,
    ILogger<ChatHub> logger) : Hub
{
    public override async Task OnConnectedAsync()
    {
        var userId = currentUser.UserId;
        if (userId is not null)
        {
            var groupName = $"user_{userId}";
            await Groups.AddToGroupAsync(Context.ConnectionId, groupName);

            // Register in presence store
            presenceStore.UserConnected(userId, Context.ConnectionId);

            // Notify other clients that this user is now online
            await Clients.Others.SendAsync("UserPresenceChanged", new
            {
                userId,
                isOnline = true,
                lastSeenAt = (DateTime?)null,
            }, Context.ConnectionAborted);

            logger.LogDebug("User {UserId} connected (connection: {ConnId})", userId, Context.ConnectionId);
        }
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = currentUser.UserId;
        if (userId is not null)
        {
            var groupName = $"user_{userId}";
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, groupName);

            // Remove from presence store (only if this exact connection)
            var lastSeenAt = presenceStore.UserDisconnected(userId, Context.ConnectionId);

            // Only notify if user is truly offline (no other tabs)
            if (lastSeenAt.HasValue)
            {
                await Clients.Others.SendAsync("UserPresenceChanged", new
                {
                    userId,
                    isOnline = false,
                    lastSeenAt,
                }, Context.ConnectionAborted);

                logger.LogDebug("User {UserId} disconnected", userId);
            }
        }
        await base.OnDisconnectedAsync(exception);
    }

    /// <summary>
    /// Called periodically by clients to keep their presence alive.
    /// </summary>
    public Task SendHeartbeat()
    {
        var userId = currentUser.UserId;
        if (userId is null) return Task.CompletedTask;

        presenceStore.Heartbeat(userId, Context.ConnectionId);
        return Task.CompletedTask;
    }
}
