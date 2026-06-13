using System.Text.Json;

namespace UniMarket.Api.Services;

/// <summary>
/// Adds missing columns to existing Cloudflare D1 tables (CREATE TABLE IF NOT EXISTS is not enough).
/// </summary>
public class D1SchemaPatcher(D1Client d1, ILogger<D1SchemaPatcher> logger)
{
    public async Task ApplyAsync(CancellationToken ct = default)
    {
        if (!d1.IsConfigured) return;

        await EnsureColumnAsync("Users", "VerifiedStudentEmail", "TEXT", ct);
        await EnsureColumnAsync("Users", "VerifiedStudentEmailAt", "TEXT", ct);
        await EnsureColumnAsync("VerificationRequests", "StudentEmail", "TEXT", ct);
        await EnsureColumnAsync("Chats", "BuyerLastReadAt", "TEXT", ct);
        await EnsureColumnAsync("Chats", "SellerLastReadAt", "TEXT", ct);
    }

    private async Task EnsureColumnAsync(
        string table,
        string column,
        string sqlType,
        CancellationToken ct)
    {
        var columns = await d1.QueryAsync($"PRAGMA table_info({table})", [], ct);
        if (ColumnExists(columns, column))
        {
            return;
        }

        await d1.ExecuteAsync($"ALTER TABLE {table} ADD COLUMN {column} {sqlType}", [], ct);
        logger.LogInformation("D1 schema patched: added {Table}.{Column}", table, column);
    }

    private static bool ColumnExists(
        IReadOnlyList<Dictionary<string, JsonElement>> columns,
        string column)
    {
        foreach (var row in columns)
        {
            if (!row.TryGetValue("name", out var nameElement))
            {
                continue;
            }

            var name = nameElement.GetString();
            if (string.Equals(name, column, StringComparison.OrdinalIgnoreCase))
            {
                return true;
            }
        }

        return false;
    }
}
