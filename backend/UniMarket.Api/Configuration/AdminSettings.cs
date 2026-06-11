namespace UniMarket.Api.Configuration;

public class AdminSettings
{
    public const string SectionName = "Admin";

    public string ApiKey { get; set; } = string.Empty;

    public bool IsConfigured => !string.IsNullOrWhiteSpace(ApiKey);
}
