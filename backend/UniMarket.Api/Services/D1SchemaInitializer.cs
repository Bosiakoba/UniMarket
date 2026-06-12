using Microsoft.Extensions.Options;
using UniMarket.Api.Configuration;

namespace UniMarket.Api.Services;

/// <summary>
/// Ensures Cloudflare D1 has the UniMarket schema when D1 is enabled.
/// </summary>
public class D1SchemaInitializer(
    IOptions<CloudflareSettings> cloudflare,
    D1Client d1,
    IWebHostEnvironment environment,
    ILogger<D1SchemaInitializer> logger)
{
    public async Task EnsureSchemaAsync(CancellationToken ct = default)
    {
        if (!cloudflare.Value.IsD1Configured || !d1.IsConfigured) return;

        var schemaPath = Path.Combine(environment.ContentRootPath, "..", "..", "cloudflare", "d1", "schema.sql");
        if (!File.Exists(schemaPath))
        {
            logger.LogWarning("D1 schema file not found at {Path}", schemaPath);
            return;
        }

        var sql = await File.ReadAllTextAsync(schemaPath, ct);
        var statements = sql
            .Split(';', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(StripLeadingComments)
            .Where(s => s.Length > 0)
            .ToList();

        var tables = statements
            .Where(s => s.Contains("CREATE TABLE", StringComparison.OrdinalIgnoreCase))
            .ToList();
        var indexes = statements
            .Where(s => s.Contains("CREATE INDEX", StringComparison.OrdinalIgnoreCase)
                || s.Contains("CREATE UNIQUE INDEX", StringComparison.OrdinalIgnoreCase))
            .ToList();
        var others = statements.Except(tables).Except(indexes).ToList();

        foreach (var statement in tables.Concat(others).Concat(indexes))
        {
            try
            {
                await d1.ExecuteAsync(statement, [], ct);
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "D1 schema statement skipped: {Statement}", Truncate(statement));
            }
        }

        logger.LogInformation("Cloudflare D1 schema initialization finished.");
    }

    private static string StripLeadingComments(string sql)
    {
        var lines = sql.Split('\n');
        var start = 0;
        while (start < lines.Length)
        {
            var trimmed = lines[start].TrimStart();
            if (trimmed.Length == 0 || trimmed.StartsWith("--", StringComparison.Ordinal))
            {
                start++;
                continue;
            }

            break;
        }

        return string.Join('\n', lines.Skip(start)).Trim();
    }

    private static string Truncate(string value) =>
        value.Length <= 80 ? value : value[..80] + "...";
}
