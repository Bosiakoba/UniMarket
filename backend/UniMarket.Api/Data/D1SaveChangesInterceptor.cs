using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.EntityFrameworkCore.Diagnostics;
using UniMarket.Api.Services;

namespace UniMarket.Api.Data;

/// <summary>
/// Mirrors EF changes to Cloudflare D1 after the in-memory SQLite cache saves.
/// </summary>
public class D1SaveChangesInterceptor(D1Client d1, D1EntitySqlBuilder sqlBuilder) : SaveChangesInterceptor
{
    public static bool SuppressSync { get; set; }

    private List<D1CapturedChange>? _captured;

    public override async ValueTask<InterceptionResult<int>> SavingChangesAsync(
        DbContextEventData eventData,
        InterceptionResult<int> result,
        CancellationToken cancellationToken = default)
    {
        if (!SuppressSync && eventData.Context is AppDbContext && d1.IsConfigured)
        {
            _captured = eventData.Context.ChangeTracker.Entries()
                .Where(e => e.State is EntityState.Added or EntityState.Modified or EntityState.Deleted)
                .Select(e => new D1CapturedChange(e, e.State))
                .ToList();

            if (_captured is { Count: > 0 })
            {
                await sqlBuilder.SyncCapturedAsync(_captured, cancellationToken);
            }
        }

        return await base.SavingChangesAsync(eventData, result, cancellationToken);
    }

    public override ValueTask<int> SavedChangesAsync(
        SaveChangesCompletedEventData eventData,
        int result,
        CancellationToken cancellationToken = default)
    {
        _captured = null;
        return base.SavedChangesAsync(eventData, result, cancellationToken);
    }
}

public sealed record D1CapturedChange(EntityEntry Entry, EntityState State);
