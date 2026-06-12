using Microsoft.EntityFrameworkCore;
using UniMarket.Api.Data;

namespace UniMarket.Api.Services;

public static class DatabaseSchemaPatcher
{
    public static async Task ApplyAsync(AppDbContext db, CancellationToken ct = default)
    {
        await db.Database.ExecuteSqlRawAsync(
            """
            CREATE TABLE IF NOT EXISTS CampusEmailOtps (
                Id TEXT NOT NULL CONSTRAINT PK_CampusEmailOtps PRIMARY KEY,
                UserId TEXT NOT NULL,
                Email TEXT NOT NULL,
                CodeHash TEXT NOT NULL,
                ExpiresAt TEXT NOT NULL,
                VerifiedAt TEXT NULL,
                CreatedAt TEXT NOT NULL
            );
            """,
            ct);

        await db.Database.ExecuteSqlRawAsync(
            """
            CREATE INDEX IF NOT EXISTS IX_CampusEmailOtps_UserId_CreatedAt
            ON CampusEmailOtps (UserId, CreatedAt);
            """,
            ct);

        await EnsureColumnAsync(db, "Users", "VerifiedStudentEmail", "TEXT NULL", ct);
        await EnsureColumnAsync(db, "Users", "VerifiedStudentEmailAt", "TEXT NULL", ct);
        await EnsureColumnAsync(db, "VerificationRequests", "StudentEmail", "TEXT NULL", ct);
    }

    private static async Task EnsureColumnAsync(
        AppDbContext db,
        string table,
        string column,
        string definition,
        CancellationToken ct)
    {
        var columns = await db.Database
            .SqlQueryRaw<ColumnInfo>($"PRAGMA table_info({table})")
            .ToListAsync(ct);

        if (columns.Any(c => string.Equals(c.name, column, StringComparison.OrdinalIgnoreCase)))
        {
            return;
        }

        await db.Database.ExecuteSqlRawAsync(
            $"ALTER TABLE {table} ADD COLUMN {column} {definition};",
            ct);
    }

    private sealed record ColumnInfo(string name);
}
