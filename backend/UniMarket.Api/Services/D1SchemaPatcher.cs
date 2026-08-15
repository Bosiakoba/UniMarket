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
        await EnsureColumnAsync("Users", "IsSuspended", "INTEGER NOT NULL DEFAULT 0", ct);
        await EnsureColumnAsync("VerificationRequests", "StudentEmail", "TEXT", ct);
        await EnsureColumnAsync("Chats", "BuyerLastReadAt", "TEXT", ct);
        await EnsureColumnAsync("Chats", "SellerLastReadAt", "TEXT", ct);
        await EnsureColumnAsync("Listings", "Views", "INTEGER NOT NULL DEFAULT 0", ct);
        await EnsureColumnAsync("Listings", "AppealComment", "TEXT", ct);
        await EnsureColumnAsync("Messages", "EditedAt", "TEXT", ct);
        await EnsureColumnAsync("Messages", "DeletedAt", "TEXT", ct);
        await EnsureColumnAsync("Messages", "DeletedForSenderId", "TEXT", ct);

        await d1.ExecuteAsync(@"
            CREATE TABLE IF NOT EXISTS CarouselBanners (
                Id TEXT PRIMARY KEY NOT NULL,
                Title TEXT NOT NULL,
                Subtitle TEXT NOT NULL,
                ImageUrl TEXT NOT NULL,
                RoutePath TEXT NOT NULL,
                CreatedAt TEXT NOT NULL
            );", [], ct);

        await d1.ExecuteAsync(@"
            CREATE TABLE IF NOT EXISTS ListingViews (
                Id TEXT PRIMARY KEY NOT NULL,
                ListingId TEXT NOT NULL,
                UserId TEXT,
                IpAddress TEXT,
                ViewedAt TEXT NOT NULL,
                FOREIGN KEY (ListingId) REFERENCES Listings(Id)
            );", [], ct);
        await d1.ExecuteAsync("CREATE INDEX IF NOT EXISTS IX_ListingViews_ListingId ON ListingViews(ListingId);", [], ct);
        await d1.ExecuteAsync("CREATE UNIQUE INDEX IF NOT EXISTS UX_ListingViews_ListingId_UserId ON ListingViews(ListingId, UserId) WHERE UserId IS NOT NULL;", [], ct);
        await d1.ExecuteAsync("CREATE UNIQUE INDEX IF NOT EXISTS UX_ListingViews_ListingId_IpAddress ON ListingViews(ListingId, IpAddress) WHERE UserId IS NULL;", [], ct);
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
