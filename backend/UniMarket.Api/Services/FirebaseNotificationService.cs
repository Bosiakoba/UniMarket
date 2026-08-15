using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Options;
using UniMarket.Api.Configuration;

namespace UniMarket.Api.Services;

public class FirebaseNotificationService(
    IOptions<FirebaseSettings> settings,
    ILogger<FirebaseNotificationService> logger)
{
    private readonly FirebaseSettings _settings = settings.Value;
    private static readonly TimeSpan[] RetryDelays = [
        TimeSpan.FromSeconds(1),
        TimeSpan.FromSeconds(2),
        TimeSpan.FromSeconds(4),
    ];

    public bool IsActive => _settings.Enabled && _settings.IsConfigured;

    /// <summary>
    /// Initializes the Firebase app during startup so credential issues surface immediately.
    /// Safe to call multiple times — returns true on success.
    /// </summary>
    public bool TryInitialize()
    {
        try
        {
            EnsureFirebaseApp();
            return true;
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "FirebaseApp initialization failed. Check credentials.");
            return false;
        }
    }

    public async Task SendAsync(
        IEnumerable<string> tokens,
        string title,
        string body,
        IReadOnlyDictionary<string, string> data,
        CancellationToken ct)
    {
        var tokenList = tokens.Where(t => !string.IsNullOrWhiteSpace(t)).Distinct().ToList();
        if (tokenList.Count == 0)
        {
            logger.LogDebug("FCM skipped: no device tokens to send to.");
            return;
        }

        if (!IsActive)
        {
            logger.LogWarning("FCM skipped: Firebase is not enabled or not configured. " +
                "Set Firebase__Enabled=true and provide service account credentials.");
            return;
        }

        try
        {
            EnsureFirebaseApp();
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "FCM failed: could not initialize FirebaseApp.");
            return;
        }

        var sentCount = 0;
        var failCount = 0;

        foreach (var token in tokenList)
        {
            if (ct.IsCancellationRequested) break;

            var delivered = await SendWithRetryAsync(token, title, body, data, ct);
            if (delivered)
                sentCount++;
            else
                failCount++;
        }

        logger.LogInformation(
            "FCM delivery complete: {SentCount} sent, {FailCount} failed out of {TotalCount} tokens.",
            sentCount, failCount, tokenList.Count);
    }

    private async Task<bool> SendWithRetryAsync(
        string token,
        string title,
        string body,
        IReadOnlyDictionary<string, string> data,
        CancellationToken ct)
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
            // High priority delivery; no custom channel — Firebase uses default channel.
            // If a custom "messages" channel is needed in future, create it on the Flutter
            // side with flutter_local_notifications before setting ChannelId here.
            Android = new AndroidConfig
            {
                Priority = Priority.High,
            },
            Apns = new ApnsConfig
            {
                Aps = new Aps
                {
                    Sound = "default",
                    Badge = 1,
                    ContentAvailable = true,
                },
            },
        };

        for (var attempt = 0; attempt <= RetryDelays.Length; attempt++)
        {
            try
            {
                await FirebaseMessaging.DefaultInstance.SendAsync(message, ct);
                return true;
            }
            catch (FirebaseMessagingException fcmEx)
            {
                // Unregistered / invalid token — no point retrying.
                // fcmEx.MessagingErrorCode exposes messaging-specific error codes
                // (Unregistered, SenderIdMismatch) not present on the base ErrorCode enum.
                if (fcmEx.MessagingErrorCode is MessagingErrorCode.Unregistered or
                    MessagingErrorCode.SenderIdMismatch or
                    MessagingErrorCode.InvalidArgument)
                {
                    logger.LogWarning("FCM: removing invalid/unregistered token (reason: {ErrorCode}).",
                        fcmEx.ErrorCode);
                    return false;
                }

                if (attempt < RetryDelays.Length)
                {
                    logger.LogWarning(fcmEx,
                        "FCM attempt {Attempt}/{Max} failed for token (quota/third-party error). Retrying...",
                        attempt + 1, RetryDelays.Length + 1);
                    await Task.Delay(RetryDelays[attempt], ct);
                }
                else
                {
                    logger.LogError(fcmEx,
                        "FCM permanently failed after {Max} attempts for a token.",
                        RetryDelays.Length + 1);
                }
            }
            catch (OperationCanceledException)
            {
                logger.LogWarning("FCM send cancelled.");
                return false;
            }
            catch (Exception ex)
            {
                if (attempt < RetryDelays.Length)
                {
                    logger.LogWarning(ex,
                        "FCM attempt {Attempt}/{Max} failed transiently. Retrying...",
                        attempt + 1, RetryDelays.Length + 1);
                    await Task.Delay(RetryDelays[attempt], ct);
                }
                else
                {
                    logger.LogError(ex,
                        "FCM permanently failed after {Max} attempts for a token.",
                        RetryDelays.Length + 1);
                }
            }
        }

        return false;
    }

    private static readonly object _initLock = new();

    private void EnsureFirebaseApp()
    {
        if (FirebaseApp.DefaultInstance is not null) return;

        lock (_initLock)
        {
            // Double-check inside the lock
            if (FirebaseApp.DefaultInstance is not null) return;

            var jsonCredentials = _settings.ResolvedServiceAccountJson;
            var credentialPath = _settings.ResolvedServiceAccountPath;

            try
            {
                if (!string.IsNullOrWhiteSpace(jsonCredentials))
                {
                    logger.LogInformation("Initializing FirebaseApp from inline JSON credentials (Project: {ProjectId}).",
                        _settings.ProjectId);
                    FirebaseApp.Create(new AppOptions
                    {
                        Credential = GoogleCredential.FromJson(jsonCredentials),
                        ProjectId = _settings.ProjectId,
                    });
                }
                else if (!string.IsNullOrWhiteSpace(credentialPath))
                {
                    if (!File.Exists(credentialPath))
                    {
                        throw new InvalidOperationException(
                            $"Firebase service account file not found at: {credentialPath}");
                    }

                    logger.LogInformation("Initializing FirebaseApp from file credentials (Project: {ProjectId}).",
                        _settings.ProjectId);
                    FirebaseApp.Create(new AppOptions
                    {
                        Credential = GoogleCredential.FromFile(credentialPath),
                        ProjectId = _settings.ProjectId,
                    });
                }
                else
                {
                    logger.LogInformation("Initializing FirebaseApp with default application credentials (Project: {ProjectId}).",
                        _settings.ProjectId);
                    FirebaseApp.Create(new AppOptions
                    {
                        ProjectId = _settings.ProjectId,
                    });
                }
            }
            catch (InvalidOperationException) when (FirebaseApp.DefaultInstance is not null)
            {
                // FirebaseAuthService or another thread already created the default app.
                logger.LogDebug("FirebaseApp already initialized by another component.");
            }
        }
    }
}
