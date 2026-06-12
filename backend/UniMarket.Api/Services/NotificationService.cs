using Microsoft.EntityFrameworkCore;
using UniMarket.Api.Data;
using UniMarket.Api.DTOs;
using UniMarket.Api.Models;

namespace UniMarket.Api.Services;

public class NotificationService(AppDbContext db, FirebaseNotificationService fcm)
{
    public async Task<UserNotification> CreateAsync(
        string userId,
        string title,
        string body,
        string type,
        string? targetId,
        string? actionLabel,
        CancellationToken ct)
    {
        var notification = new UserNotification
        {
            Id = Guid.NewGuid().ToString("N")[..12],
            UserId = userId,
            Title = title,
            Body = body,
            Type = type,
            TargetId = targetId,
            ActionLabel = actionLabel,
            CreatedAt = DateTime.UtcNow,
        };

        db.UserNotifications.Add(notification);
        await db.SaveChangesAsync(ct);

        var tokens = await db.DeviceRegistrations
            .Where(d => d.UserId == userId)
            .Select(d => d.Token)
            .ToListAsync(ct);

        await fcm.SendAsync(
            tokens,
            title,
            body,
            new Dictionary<string, string>
            {
                ["notificationId"] = notification.Id,
                ["type"] = type,
                ["targetId"] = targetId ?? "",
            },
            ct);

        return notification;
    }

    public async Task<List<NotificationDto>> ListAsync(string userId, CancellationToken ct)
    {
        var rows = await db.UserNotifications
            .Where(n => n.UserId == userId)
            .OrderByDescending(n => n.CreatedAt)
            .Take(100)
            .ToListAsync(ct);

        return rows.Select(ToDto).ToList();
    }

    public async Task RegisterDeviceAsync(
        string userId,
        string token,
        string? platform,
        CancellationToken ct)
    {
        var trimmed = token.Trim();
        var row = await db.DeviceRegistrations
            .FirstOrDefaultAsync(d => d.Token == trimmed, ct);

        if (row is null)
        {
            db.DeviceRegistrations.Add(new DeviceRegistration
            {
                Id = Guid.NewGuid().ToString("N")[..12],
                UserId = userId,
                Token = trimmed,
                Platform = string.IsNullOrWhiteSpace(platform) ? "unknown" : platform.Trim(),
                UpdatedAt = DateTime.UtcNow,
            });
        }
        else
        {
            row.UserId = userId;
            row.Platform = string.IsNullOrWhiteSpace(platform) ? row.Platform : platform.Trim();
            row.UpdatedAt = DateTime.UtcNow;
        }

        await db.SaveChangesAsync(ct);
    }

    public async Task MarkReadAsync(string userId, string id, CancellationToken ct)
    {
        var row = await db.UserNotifications
            .FirstOrDefaultAsync(n => n.Id == id && n.UserId == userId, ct);
        if (row is null) return;

        row.IsRead = true;
        await db.SaveChangesAsync(ct);
    }

    public async Task MarkAllReadAsync(string userId, CancellationToken ct)
    {
        var rows = await db.UserNotifications
            .Where(n => n.UserId == userId && !n.IsRead)
            .ToListAsync(ct);

        foreach (var row in rows) row.IsRead = true;
        await db.SaveChangesAsync(ct);
    }

    public static NotificationDto ToDto(UserNotification row) =>
        new(
            row.Id,
            row.Title,
            row.Body,
            row.Type,
            row.TargetId,
            row.ActionLabel,
            row.IsRead,
            row.CreatedAt,
            FormatTimeLabel(row.CreatedAt));

    private static string FormatTimeLabel(DateTime createdAt)
    {
        var delta = DateTime.UtcNow - createdAt;
        if (delta.TotalMinutes < 1) return "Just now";
        if (delta.TotalHours < 1) return $"{(int)delta.TotalMinutes}m";
        if (delta.TotalDays < 1) return $"{(int)delta.TotalHours}h";
        if (delta.TotalDays < 7) return $"{(int)delta.TotalDays}d";
        return createdAt.ToString("MMM d");
    }
}
