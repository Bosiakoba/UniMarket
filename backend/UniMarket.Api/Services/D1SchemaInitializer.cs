using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Options;
using UniMarket.Api.Configuration;

namespace UniMarket.Api.Services;

/// <summary>
/// Ensures Cloudflare D1 has the UniMarket schema when D1 is enabled.
/// The home-server API still uses on-disk SQLite; D1 is kept in sync for Workers/admin tools.
/// </summary>
public class D1SchemaInitializer(
    IOptions<CloudflareSettings> cloudflare,
    IHttpClientFactory httpClientFactory,
    IWebHostEnvironment environment,
    ILogger<D1SchemaInitializer> logger)
{
    public async Task EnsureSchemaAsync(CancellationToken ct = default)
    {
        var settings = cloudflare.Value;
        if (!settings.IsD1Configured) return;

        var schemaPath = Path.Combine(environment.ContentRootPath, "..", "..", "cloudflare", "d1", "schema.sql");
        if (!File.Exists(schemaPath))
        {
            logger.LogWarning("D1 schema file not found at {Path}", schemaPath);
            return;
        }

        var sql = await File.ReadAllTextAsync(schemaPath, ct);
        var statements = sql
            .Split(';', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Where(s => !string.IsNullOrWhiteSpace(s) && !s.StartsWith("--", StringComparison.Ordinal))
            .ToList();

        var client = httpClientFactory.CreateClient(nameof(D1SchemaInitializer));
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", settings.D1ApiToken);

        var url =
            $"https://api.cloudflare.com/client/v4/accounts/{settings.AccountId}/d1/database/{settings.D1DatabaseId}/query";

        foreach (var statement in statements)
        {
            var body = JsonSerializer.Serialize(new { sql = statement });
            using var content = new StringContent(body, Encoding.UTF8, "application/json");
            var response = await client.PostAsync(url, content, ct);
            if (!response.IsSuccessStatusCode)
            {
                var error = await response.Content.ReadAsStringAsync(ct);
                logger.LogWarning("D1 schema statement failed: {Error}", error);
            }
        }

        logger.LogInformation("Cloudflare D1 schema initialization finished.");
    }
}
