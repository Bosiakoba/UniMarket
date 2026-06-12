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

        await EnsureColumnAsync(
            db,
            table: "Users",
            column: "VerifiedStudentEmail",
            alterSql: "ALTER TABLE Users ADD COLUMN VerifiedStudentEmail TEXT NULL;",
            ct);
        await EnsureColumnAsync(
            db,
            table: "Users",
            column: "VerifiedStudentEmailAt",
            alterSql: "ALTER TABLE Users ADD COLUMN VerifiedStudentEmailAt TEXT NULL;",
            ct);
        await EnsureColumnAsync(
            db,
            table: "VerificationRequests",
            column: "StudentEmail",
            alterSql: "ALTER TABLE VerificationRequests ADD COLUMN StudentEmail TEXT NULL;",
            ct);
        await EnsureColumnAsync(
            db,
            table: "Chats",
            column: "BuyerLastReadAt",
            alterSql: "ALTER TABLE Chats ADD COLUMN BuyerLastReadAt TEXT NULL;",
            ct);
        await EnsureColumnAsync(
            db,
            table: "Chats",
            column: "SellerLastReadAt",
            alterSql: "ALTER TABLE Chats ADD COLUMN SellerLastReadAt TEXT NULL;",
            ct);
    }

    private static async Task EnsureColumnAsync(
        AppDbContext db,
        string table,
        string column,
        string alterSql,
        CancellationToken ct)
    {
        if (await ColumnExistsAsync(db, table, column, ct))
        {
            return;
        }

        await db.Database.ExecuteSqlRawAsync(alterSql, ct);
    }

    private static async Task<bool> ColumnExistsAsync(
        AppDbContext db,
        string table,
        string column,
        CancellationToken ct)
    {
        var columns = table switch
        {
            "Users" => await db.Database
                .SqlQueryRaw<ColumnInfo>("PRAGMA table_info(Users)")
                .ToListAsync(ct),
            "VerificationRequests" => await db.Database
                .SqlQueryRaw<ColumnInfo>("PRAGMA table_info(VerificationRequests)")
                .ToListAsync(ct),
            "Chats" => await db.Database
                .SqlQueryRaw<ColumnInfo>("PRAGMA table_info(Chats)")
                .ToListAsync(ct),
            _ => throw new InvalidOperationException($"Unsupported schema table: {table}"),
        };

        return columns.Any(c =>
            string.Equals(c.name, column, StringComparison.OrdinalIgnoreCase));
    }

    private sealed record ColumnInfo(string name);
}
