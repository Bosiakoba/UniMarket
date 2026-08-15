namespace UniMarket.Api.Configuration;

public class ApiSettings
{
    public const string SectionName = "Api";

    /// <summary>Public URL of this API (used for locally stored upload URLs).</summary>
    public string PublicBaseUrl { get; set; } = "http://localhost:5080";
}
