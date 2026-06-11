namespace UniMarket.Api.Configuration;

public class CloudflareSettings
{
    public const string SectionName = "Cloudflare";

    public string AccountId { get; set; } = string.Empty;

    public string D1DatabaseId { get; set; } = string.Empty;

    public string D1ApiToken { get; set; } = string.Empty;

    public bool D1Enabled { get; set; }

    public bool R2Enabled { get; set; }

    public string R2AccessKeyId { get; set; } = string.Empty;

    public string R2SecretAccessKey { get; set; } = string.Empty;

    public string R2BucketName { get; set; } = "unimarket-assets";

    /// <summary>Example: https://&lt;account_id&gt;.r2.cloudflarestorage.com</summary>
    public string R2Endpoint { get; set; } = string.Empty;

    public bool IsD1Configured =>
        D1Enabled &&
        !string.IsNullOrWhiteSpace(AccountId) &&
        !string.IsNullOrWhiteSpace(D1DatabaseId) &&
        !string.IsNullOrWhiteSpace(D1ApiToken);

    public bool IsR2Configured =>
        R2Enabled &&
        !string.IsNullOrWhiteSpace(R2AccessKeyId) &&
        !string.IsNullOrWhiteSpace(R2SecretAccessKey) &&
        !string.IsNullOrWhiteSpace(R2BucketName) &&
        !string.IsNullOrWhiteSpace(R2Endpoint);
}
