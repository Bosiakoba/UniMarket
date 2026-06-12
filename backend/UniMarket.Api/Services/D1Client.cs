using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.Extensions.Options;
using UniMarket.Api.Configuration;

namespace UniMarket.Api.Services;

/// <summary>
/// Cloudflare D1 HTTP API client. All persistent data lives in D1 when enabled.
/// </summary>
public class D1Client(
    IHttpClientFactory httpClientFactory,
    IOptions<CloudflareSettings> cloudflare,
    ILogger<D1Client> logger)
{
    private static readonly JsonSerializerOptions JsonDeserializeOptions = new()
    {
        PropertyNameCaseInsensitive = true,
    };

    private static readonly JsonSerializerOptions JsonSerializeOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
    };

    private readonly CloudflareSettings _settings = cloudflare.Value;

    public bool IsConfigured => _settings.IsD1Configured;

    public async Task<IReadOnlyList<Dictionary<string, JsonElement>>> QueryAsync(
        string sql,
        IReadOnlyList<object?>? parameters = null,
        CancellationToken ct = default)
    {
        var response = await ExecuteInternalAsync(sql, parameters, ct);
        return response.Results;
    }

    public async Task ExecuteAsync(
        string sql,
        IReadOnlyList<object?>? parameters = null,
        CancellationToken ct = default)
    {
        await ExecuteInternalAsync(sql, parameters, ct);
    }

    public async Task<bool> TableHasRowsAsync(string table, CancellationToken ct = default)
    {
        try
        {
            var rows = await QueryAsync($"SELECT 1 AS ok FROM {table} LIMIT 1", [], ct);
            return rows.Count > 0;
        }
        catch (Exception ex)
        {
            logger.LogDebug(ex, "D1 table {Table} is empty or not readable yet.", table);
            return false;
        }
    }

    private async Task<D1QueryResult> ExecuteInternalAsync(
        string sql,
        IReadOnlyList<object?>? parameters,
        CancellationToken ct)
    {
        if (!IsConfigured)
        {
            throw new InvalidOperationException("Cloudflare D1 is not configured.");
        }

        var client = httpClientFactory.CreateClient(nameof(D1Client));
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", _settings.D1ApiToken);

        var url =
            $"https://api.cloudflare.com/client/v4/accounts/{_settings.AccountId}/d1/database/{_settings.D1DatabaseId}/query";

        var payload = JsonSerializer.Serialize(
            new D1Request(sql, parameters ?? []),
            JsonSerializeOptions);
        using var content = new StringContent(payload, Encoding.UTF8, "application/json");
        var response = await client.PostAsync(url, content, ct);
        var body = await response.Content.ReadAsStringAsync(ct);

        if (!response.IsSuccessStatusCode)
        {
            logger.LogError("D1 query failed ({Status}): {Body}", response.StatusCode, body);
            throw new InvalidOperationException($"D1 query failed: {response.StatusCode}");
        }

        var envelope = JsonSerializer.Deserialize<D1Envelope>(body, JsonDeserializeOptions);
        if (envelope is null || !envelope.Success || envelope.Result is null || envelope.Result.Count == 0)
        {
            throw new InvalidOperationException("D1 returned an empty or unsuccessful response.");
        }

        var result = envelope.Result[0];
        if (!result.Success)
        {
            var errors = result.Errors is { Count: > 0 }
                ? string.Join("; ", result.Errors)
                : "unknown D1 error";
            throw new InvalidOperationException($"D1 statement failed: {errors}");
        }

        return result;
    }

    private sealed record D1Request(string Sql, IReadOnlyList<object?> Params);

    private sealed class D1Envelope
    {
        [JsonPropertyName("success")]
        public bool Success { get; set; }

        [JsonPropertyName("result")]
        public List<D1QueryResult>? Result { get; set; }
    }

    private sealed class D1QueryResult
    {
        [JsonPropertyName("results")]
        public List<Dictionary<string, JsonElement>> Results { get; set; } = [];

        [JsonPropertyName("success")]
        public bool Success { get; set; }

        [JsonPropertyName("errors")]
        public List<string>? Errors { get; set; }
    }
}
