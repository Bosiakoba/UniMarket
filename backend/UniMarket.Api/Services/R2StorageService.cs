using Amazon.Runtime;
using Amazon.S3;
using Amazon.S3.Model;
using Microsoft.Extensions.Options;
using UniMarket.Api.Configuration;

namespace UniMarket.Api.Services;

public class R2StorageService : IDisposable
{
    private readonly CloudflareSettings _settings;
    private IAmazonS3? _client;
    private bool _disposed;

    public R2StorageService(IOptions<CloudflareSettings> settings)
    {
        _settings = settings.Value;
    }

    public bool IsConfigured => _settings.IsR2Configured;

    private IAmazonS3 Client
    {
        get
        {
            ObjectDisposedException.ThrowIf(_disposed, this);
            if (_client is not null) return _client;

            var config = new AmazonS3Config
            {
                ServiceURL = _settings.R2Endpoint.Trim(),
                ForcePathStyle = true,
                AuthenticationRegion = "auto",
            };

            _client = new AmazonS3Client(
                new BasicAWSCredentials(_settings.R2AccessKeyId, _settings.R2SecretAccessKey),
                config);

            return _client;
        }
    }

    public async Task<string> UploadListingPhotoAsync(
        Stream stream,
        string contentType,
        string userId,
        CancellationToken ct)
    {
        if (!IsConfigured)
        {
            throw new InvalidOperationException("Cloudflare R2 is not configured.");
        }

        var extension = contentType switch
        {
            "image/png" => ".png",
            "image/webp" => ".webp",
            "image/heic" => ".heic",
            "image/heif" => ".heif",
            _ => ".jpg",
        };

        var key = $"listings/{userId}/{Guid.NewGuid():N}{extension}";

        var request = new PutObjectRequest
        {
            BucketName = _settings.R2BucketName,
            Key = key,
            InputStream = stream,
            ContentType = contentType,
            DisablePayloadSigning = true,
            DisableDefaultChecksumValidation = true,
        };

        await Client.PutObjectAsync(request, ct);

        var baseUrl = _settings.R2PublicBaseUrl.Trim().TrimEnd('/');
        return $"{baseUrl}/{key}";
    }

    public void Dispose()
    {
        if (_disposed) return;
        _client?.Dispose();
        _disposed = true;
    }
}
