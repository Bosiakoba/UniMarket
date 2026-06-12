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

    public override ValueTask<InterceptionResult<int>> SavingChangesAsync(
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
        }

        return base.SavingChangesAsync(eventData, result, cancellationToken);
    }

    public override async ValueTask<int> SavedChangesAsync(
        SaveChangesCompletedEventData eventData,
        int result,
        CancellationToken cancellationToken = default)
    {
        if (result > 0 && _captured is { Count: > 0 })
        {
            await sqlBuilder.SyncCapturedAsync(_captured, cancellationToken);
            _captured = null;
        }

        return await base.SavedChangesAsync(eventData, result, cancellationToken);
    }
}

public sealed record D1CapturedChange(EntityEntry Entry, EntityState State);
