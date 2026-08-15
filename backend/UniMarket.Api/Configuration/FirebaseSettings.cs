namespace UniMarket.Api.Configuration;

public class FirebaseSettings
{
    public const string SectionName = "Firebase";

    public string ProjectId { get; set; } = string.Empty;

    public bool Enabled { get; set; }

    /// <summary>Path to service account JSON on the server (GOOGLE_APPLICATION_CREDENTIALS).</summary>
    public string? ServiceAccountPath { get; set; }

    /// <summary>Inline JSON content of the service account. Used on Railway/cloud where file paths don't exist.</summary>
    public string? ServiceAccountJson { get; set; }

    public bool IsConfigured =>
        Enabled &&
        !string.IsNullOrWhiteSpace(ProjectId) &&
        HasValidCredentials;

    private bool HasValidCredentials =>
        !string.IsNullOrWhiteSpace(ResolvedServiceAccountJson) ||
        (!string.IsNullOrWhiteSpace(ResolvedServiceAccountPath) &&
         File.Exists(ResolvedServiceAccountPath));

    public string? ResolvedServiceAccountPath =>
        !string.IsNullOrWhiteSpace(ServiceAccountPath)
            ? ServiceAccountPath
            : Environment.GetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS");

    /// <summary>Returns the inline JSON if set, otherwise reads from the file path.</summary>
    public string? ResolvedServiceAccountJson =>
        !string.IsNullOrWhiteSpace(ServiceAccountJson)
            ? ServiceAccountJson
            : Environment.GetEnvironmentVariable("Firebase__ServiceAccountJson");
}
