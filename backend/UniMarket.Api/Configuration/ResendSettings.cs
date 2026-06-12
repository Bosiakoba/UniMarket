namespace UniMarket.Api.Configuration;

public class ResendSettings
{
    public const string SectionName = "Resend";

    public string ApiKey { get; set; } = string.Empty;

    /// <summary>e.g. UniMarket &lt;noreply@yourdomain.com&gt;</summary>
    public string FromAddress { get; set; } = "UniMarket <onboarding@resend.dev>";

    public bool Enabled { get; set; }

    public bool IsConfigured =>
        Enabled && !string.IsNullOrWhiteSpace(ApiKey) && !string.IsNullOrWhiteSpace(FromAddress);
}
