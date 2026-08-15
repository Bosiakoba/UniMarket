using System.Collections.Concurrent;

namespace UniMarket.Api.Services;

/// <summary>
/// Thread-safe in-memory store that tracks which users are currently connected
/// to the SignalR hub and when each connection was last seen.
///
/// A user may hold multiple concurrent connections (multiple tabs/devices).
/// A user is considered "online" while at least one of their connections has a
/// recent heartbeat, so closing one tab never falsely marks a user offline while
/// another connection is still live.
/// </summary>
public class UserPresenceStore
{
    // userId -> (connectionId -> lastHeartbeatUtc)
    private readonly ConcurrentDictionary<string, ConcurrentDictionary<string, DateTime>> _connections = new();

    private static readonly TimeSpan StaleThreshold = TimeSpan.FromSeconds(60);
    private static readonly TimeSpan CleanupThreshold = TimeSpan.FromSeconds(120);

    /// <summary>Registers a new connection for the user.</summary>
    public void UserConnected(string userId, string connectionId)
    {
        var conns = _connections.GetOrAdd(userId, _ => new ConcurrentDictionary<string, DateTime>());
        conns[connectionId] = DateTime.UtcNow;
    }

    /// <summary>
    /// Removes a connection. Returns the user's last-known timestamp only if this
    /// was their LAST connection (so the hub can broadcast that they went offline),
    /// or null if the user still has other live connections.
    /// </summary>
    public DateTime? UserDisconnected(string userId, string connectionId)
    {
        if (!_connections.TryGetValue(userId, out var conns))
        {
            return null;
        }

        conns.TryRemove(connectionId, out var removedAt);

        if (conns.IsEmpty)
        {
            _connections.TryRemove(userId, out _);
            return removedAt != default ? removedAt : DateTime.UtcNow;
        }

        return null;
    }

    /// <summary>Updates the heartbeat for a specific connection.</summary>
    public void Heartbeat(string userId, string connectionId)
    {
        var conns = _connections.GetOrAdd(userId, _ => new ConcurrentDictionary<string, DateTime>());
        conns[connectionId] = DateTime.UtcNow;
    }

    /// <summary>
    /// Returns (isOnline, lastSeenAt). A user is online if at least one connection
    /// has a heartbeat within the stale threshold. lastSeenAt is the most recent
    /// heartbeat across all connections (or null if the user has never been seen).
    /// </summary>
    public (bool isOnline, DateTime? lastSeenAt) GetPresence(string userId)
    {
        if (!_connections.TryGetValue(userId, out var conns))
        {
            return (false, null);
        }

        var now = DateTime.UtcNow;
        DateTime? lastSeen = null;
        var isOnline = false;

        foreach (var heartbeat in conns.Values)
        {
            if (heartbeat > lastSeen)
            {
                lastSeen = heartbeat;
            }

            if ((now - heartbeat) <= StaleThreshold)
            {
                isOnline = true;
            }
        }

        return (isOnline, lastSeen);
    }

    /// <summary>Returns the ids of all users currently considered online.</summary>
    public IReadOnlyCollection<string> GetOnlineUserIds()
    {
        var now = DateTime.UtcNow;
        var online = new List<string>();

        foreach (var kvp in _connections)
        {
            foreach (var heartbeat in kvp.Value.Values)
            {
                if ((now - heartbeat) <= StaleThreshold)
                {
                    online.Add(kvp.Key);
                    break;
                }
            }
        }

        return online;
    }

    /// <summary>
    /// Removes stale connections (no heartbeat within the cleanup threshold) and
    /// drops user buckets that end up with no connections. Returns a mapping of
    /// users that became fully offline to their last-known heartbeat, so callers
    /// can broadcast the presence change to other clients.
    /// </summary>
    public IReadOnlyDictionary<string, DateTime> CleanupStale()
    {
        var removed = new Dictionary<string, DateTime>();
        var cutoff = DateTime.UtcNow.Add(-CleanupThreshold);

        foreach (var kvp in _connections)
        {
            DateTime? removedLast = null;

            foreach (var conn in kvp.Value)
            {
                if (conn.Value < cutoff)
                {
                    kvp.Value.TryRemove(conn.Key, out _);
                    if (removedLast == null || conn.Value > removedLast)
                    {
                        removedLast = conn.Value;
                    }
                }
            }

            if (kvp.Value.IsEmpty)
            {
                _connections.TryRemove(kvp.Key, out _);
                removed[kvp.Key] = removedLast ?? cutoff;
            }
        }

        return removed;
    }
}
