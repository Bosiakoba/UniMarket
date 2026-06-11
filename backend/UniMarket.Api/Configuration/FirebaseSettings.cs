namespace UniMarket.Api.Configuration;

public class FirebaseSettings
{
    public const string SectionName = "Firebase";

    public string ProjectId { get; set; } = string.Empty;

    public bool Enabled { get; set; }

    /// <summary>Path to service account JSON on the server (GOOGLE_APPLICATION_CREDENTIALS).</summary>
    public string? ServiceAccountPath { get; set; }

    public bool IsConfigured =>
        Enabled &&
        !string.IsNullOrWhiteSpace(ProjectId) &&
        !string.IsNullOrWhiteSpace(ResolvedServiceAccountPath) &&
        File.Exists(ResolvedServiceAccountPath);

    public string? ResolvedServiceAccountPath =>
        !string.IsNullOrWhiteSpace(ServiceAccountPath)
            ? ServiceAccountPath
            : Environment.GetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS");
}
