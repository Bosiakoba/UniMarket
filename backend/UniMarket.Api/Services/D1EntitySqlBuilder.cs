using System.Globalization;
using System.Reflection;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.EntityFrameworkCore.Metadata;
using UniMarket.Api.Data;

namespace UniMarket.Api.Services;

public class D1EntitySqlBuilder(D1Client d1, ILogger<D1EntitySqlBuilder> logger)
{
    private static readonly string[] HydrationOrder =
    [
        "Users",
        "Listings",
        "ListingImages",
        "Chats",
        "Messages",
        "CampusEmailOtps",
        "VerificationRequests",
        "ListingReviews",
        "ListingReports",
        "WishlistItems",
        "SaleRecords",
        "SaleConfirmations",
        "DeviceRegistrations",
        "UserNotifications",
    ];

    public async Task HydrateAsync(AppDbContext db, CancellationToken ct = default)
    {
        foreach (var table in HydrationOrder)
        {
            var entityType = db.Model.GetEntityTypes()
                .FirstOrDefault(t => string.Equals(t.GetTableName(), table, StringComparison.OrdinalIgnoreCase));
            if (entityType is null) continue;

            var rows = await d1.QueryAsync($"SELECT * FROM {table}", null, ct);
            if (rows.Count == 0) continue;

            var clrType = entityType.ClrType;
            foreach (var row in rows)
            {
                var entity = Activator.CreateInstance(clrType);
                if (entity is null) continue;

                foreach (var property in clrType.GetProperties(BindingFlags.Public | BindingFlags.Instance))
                {
                    if (!property.CanWrite || property.GetIndexParameters().Length > 0) continue;
                    if (!row.TryGetValue(property.Name, out var value)) continue;
                    property.SetValue(entity, ConvertJsonValue(value, property.PropertyType));
                }

                db.Add(entity);
            }
        }

        D1SaveChangesInterceptor.SuppressSync = true;
        try
        {
            await db.SaveChangesAsync(ct);
        }
        finally
        {
            D1SaveChangesInterceptor.SuppressSync = false;
        }

        db.ChangeTracker.Clear();
        logger.LogInformation("Hydrated in-memory cache from Cloudflare D1.");
    }

    public async Task SyncCapturedAsync(
        IReadOnlyList<D1CapturedChange> changes,
        CancellationToken ct = default)
    {
        foreach (var captured in changes.OrderBy(c => c.State == EntityState.Deleted ? 0 : 1))
        {
            var entry = captured.Entry;
            var table = entry.Metadata.GetTableName()
                ?? throw new InvalidOperationException("Missing table mapping.");

            switch (captured.State)
            {
                case EntityState.Added:
                    await d1.ExecuteAsync(BuildInsert(table, entry), GetParameterValues(entry), ct);
                    break;
                case EntityState.Modified:
                    await d1.ExecuteAsync(
                        BuildUpdate(table, entry),
                        GetUpdateParameterValues(entry),
                        ct);
                    break;
                case EntityState.Deleted:
                    await d1.ExecuteAsync(
                        BuildDelete(table, entry),
                        GetDeletedKeyParameterValues(entry),
                        ct);
                    break;
            }
        }
    }

    private static string BuildInsert(string table, Microsoft.EntityFrameworkCore.ChangeTracking.EntityEntry entry)
    {
        var columns = GetMappedProperties(entry).ToList();
        var names = string.Join(", ", columns.Select(c => c.Name));
        var placeholders = string.Join(", ", columns.Select(_ => "?"));
        return $"INSERT INTO {table} ({names}) VALUES ({placeholders})";
    }

    private static string BuildUpdate(string table, Microsoft.EntityFrameworkCore.ChangeTracking.EntityEntry entry)
    {
        var columns = GetMappedProperties(entry).ToList();
        var setClause = string.Join(", ", columns.Select(c => $"{c.Name} = ?"));
        var key = entry.Metadata.FindPrimaryKey()
            ?? throw new InvalidOperationException("Entity has no primary key.");
        var whereClause = string.Join(" AND ", key.Properties.Select(p => $"{p.Name} = ?"));
        return $"UPDATE {table} SET {setClause} WHERE {whereClause}";
    }

    private static string BuildDelete(string table, Microsoft.EntityFrameworkCore.ChangeTracking.EntityEntry entry)
    {
        var key = entry.Metadata.FindPrimaryKey()
            ?? throw new InvalidOperationException("Entity has no primary key.");
        var whereClause = string.Join(" AND ", key.Properties.Select(p => $"{p.Name} = ?"));
        return $"DELETE FROM {table} WHERE {whereClause}";
    }

    private static IEnumerable<IProperty> GetMappedProperties(
        Microsoft.EntityFrameworkCore.ChangeTracking.EntityEntry entry) =>
        entry.Properties
            .Where(p => !p.Metadata.IsShadowProperty())
            .Select(p => p.Metadata);

    private static IReadOnlyList<object?> GetParameterValues(
        Microsoft.EntityFrameworkCore.ChangeTracking.EntityEntry entry) =>
        entry.Properties
            .Where(p => !p.Metadata.IsShadowProperty())
            .Select(p => ToDbValue(p.CurrentValue))
            .ToList();

    private static IReadOnlyList<object?> GetUpdateParameterValues(EntityEntry entry)
    {
        var values = GetParameterValues(entry).ToList();
        values.AddRange(GetDeletedKeyParameterValues(entry));
        return values;
    }

    private static IReadOnlyList<object?> GetDeletedKeyParameterValues(EntityEntry entry)
    {
        var key = entry.Metadata.FindPrimaryKey()
            ?? throw new InvalidOperationException("Entity has no primary key.");
        return key.Properties
            .Select(p => ToDbValue(entry.Property(p.Name).OriginalValue ?? entry.Property(p.Name).CurrentValue))
            .ToList();
    }

    private static object? ConvertJsonValue(JsonElement value, Type targetType)
    {
        var underlying = Nullable.GetUnderlyingType(targetType) ?? targetType;
        if (value.ValueKind is JsonValueKind.Null or JsonValueKind.Undefined)
        {
            return null;
        }

        if (underlying == typeof(string)) return value.GetString();
        if (underlying == typeof(bool)) return value.ValueKind == JsonValueKind.Number ? value.GetInt32() == 1 : value.GetBoolean();
        if (underlying == typeof(int)) return value.GetInt32();
        if (underlying == typeof(double)) return value.GetDouble();
        if (underlying == typeof(decimal)) return value.GetDecimal();
        if (underlying == typeof(DateTime)) return DateTime.Parse(value.GetString()!, CultureInfo.InvariantCulture, DateTimeStyles.RoundtripKind);
        if (underlying == typeof(Guid)) return Guid.Parse(value.GetString()!);

        return JsonSerializer.Deserialize(value.GetRawText(), targetType);
    }

    private static object? ToDbValue(object? value) =>
        value switch
        {
            null => null,
            bool b => b ? 1 : 0,
            DateTime dt => dt.ToUniversalTime().ToString("O", CultureInfo.InvariantCulture),
            DateTimeOffset dto => dto.UtcDateTime.ToString("O", CultureInfo.InvariantCulture),
            decimal dec => dec,
            double dbl => dbl,
            float fl => fl,
            _ => value,
        };
}
