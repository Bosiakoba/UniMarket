using FirebaseAdmin;
using FirebaseAdmin.Auth;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Options;
using UniMarket.Api.Configuration;

namespace UniMarket.Api.Services;

public sealed class FirebaseAuthService : IDisposable
{
    private readonly FirebaseSettings _settings;
    private FirebaseAuth? _auth;
    private bool _disposed;

    public FirebaseAuthService(IOptions<FirebaseSettings> settings)
    {
        _settings = settings.Value;
    }

    public bool IsActive => _settings.Enabled && _settings.IsConfigured;

    public FirebaseAuth Auth
    {
        get
        {
            ObjectDisposedException.ThrowIf(_disposed, this);
            if (_auth is not null) return _auth;

            if (FirebaseApp.DefaultInstance is null)
            {
                var credentialJson = _settings.ResolvedServiceAccountJson;
                GoogleCredential credential;

                if (!string.IsNullOrWhiteSpace(credentialJson))
                {
                    credential = GoogleCredential.FromJson(credentialJson);
                }
                else
                {
                    var credentialPath = _settings.ResolvedServiceAccountPath
                        ?? throw new InvalidOperationException(
                            "Firebase credentials not configured. Set either Firebase__ServiceAccountJson " +
                            "(inline JSON) or GOOGLE_APPLICATION_CREDENTIALS (file path).");
                    credential = GoogleCredential.FromFile(credentialPath);
                }

                FirebaseApp.Create(new AppOptions
                {
                    Credential = credential,
                    ProjectId = _settings.ProjectId,
                });
            }

            _auth = FirebaseAuth.DefaultInstance;
            return _auth;
        }
    }

    public async Task<FirebaseToken> VerifyIdTokenAsync(string idToken, CancellationToken ct)
    {
        if (!IsActive)
        {
            throw new InvalidOperationException("Firebase auth is not enabled.");
        }

        return await Auth.VerifyIdTokenAsync(idToken, ct);
    }

    public void Dispose()
    {
        if (_disposed) return;
        _disposed = true;
    }
}
