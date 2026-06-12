using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Options;
using UniMarket.Api.Configuration;

namespace UniMarket.Api.Services;

public class FirebaseNotificationService(IOptions<FirebaseSettings> settings, ILogger<FirebaseNotificationService> logger)
{
    private readonly FirebaseSettings _settings = settings.Value;

    public bool IsActive => _settings.Enabled && _settings.IsConfigured;

    public async Task SendAsync(
        IEnumerable<string> tokens,
        string title,
        string body,
        IReadOnlyDictionary<string, string> data,
        CancellationToken ct)
    {
        var tokenList = tokens.Where(t => !string.IsNullOrWhiteSpace(t)).Distinct().ToList();
        if (tokenList.Count == 0 || !IsActive) return;

        try
        {
            EnsureFirebaseApp();
            foreach (var token in tokenList)
            {
                var message = new Message
                {
                    Token = token,
                    Notification = new Notification
                    {
                        Title = title,
                        Body = body,
                    },
                    Data = data.ToDictionary(k => k.Key, v => v.Value),
                };

                await FirebaseMessaging.DefaultInstance.SendAsync(message, cancellationToken: ct);
            }
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "FCM delivery failed.");
        }
    }

    private void EnsureFirebaseApp()
    {
        if (FirebaseApp.DefaultInstance is not null) return;

        var credentialPath = _settings.ResolvedServiceAccountPath
            ?? throw new InvalidOperationException("Firebase service account path is not configured.");

        FirebaseApp.Create(new AppOptions
        {
            Credential = GoogleCredential.FromFile(credentialPath),
            ProjectId = _settings.ProjectId,
        });
    }
}
