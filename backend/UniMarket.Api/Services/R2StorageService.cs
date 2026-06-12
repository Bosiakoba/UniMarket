using Amazon.Runtime;
using Amazon.S3;
using Amazon.S3.Model;
using Microsoft.Extensions.Options;
using UniMarket.Api.Configuration;

namespace UniMarket.Api.Services;

public class R2StorageService : IDisposable
{
    private readonly CloudflareSettings _settings;
    private readonly ApiSettings _apiSettings;
    private readonly string _localUploadRoot;
    private IAmazonS3? _client;
    private bool _disposed;

    public R2StorageService(
        IOptions<CloudflareSettings> settings,
        IOptions<ApiSettings> apiSettings,
        IWebHostEnvironment environment)
    {
        _settings = settings.Value;
        _apiSettings = apiSettings.Value;
        _localUploadRoot = Path.Combine(environment.ContentRootPath, "data", "uploads");
    }

    public bool IsR2Configured => _settings.IsR2Configured;

    public bool UsesLocalFallback => !_settings.IsR2Configured && _settings.AllowLocalUploadFallback;

    public bool CanUpload => _settings.CanUploadFiles;

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
        CancellationToken ct) =>
        await UploadAsync(stream, contentType, $"listings/{userId}", ct);

    public async Task<string> UploadSellerDocumentAsync(
        Stream stream,
        string contentType,
        string userId,
        CancellationToken ct) =>
        await UploadAsync(stream, contentType, $"seller-documents/{userId}", ct);

    private async Task<string> UploadAsync(
        Stream stream,
        string contentType,
        string prefix,
        CancellationToken ct)
    {
        if (!CanUpload)
        {
            throw new InvalidOperationException("File upload is not configured on the server.");
        }

        var extension = contentType switch
        {
            "image/png" => ".png",
            "image/webp" => ".webp",
            "image/heic" => ".heic",
            "image/heif" => ".heif",
            _ => ".jpg",
        };

        var key = $"{prefix.Trim('/')}/{Guid.NewGuid():N}{extension}";

        if (UsesLocalFallback)
        {
            return await UploadLocalAsync(stream, key, ct);
        }

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

    private async Task<string> UploadLocalAsync(Stream stream, string key, CancellationToken ct)
    {
        var filePath = Path.Combine(_localUploadRoot, key.Replace('/', Path.DirectorySeparatorChar));
        var directory = Path.GetDirectoryName(filePath);
        if (!string.IsNullOrWhiteSpace(directory))
        {
            Directory.CreateDirectory(directory);
        }

        await using var file = File.Create(filePath);
        await stream.CopyToAsync(file, ct);

        var publicBase = _apiSettings.PublicBaseUrl.Trim().TrimEnd('/');
        return $"{publicBase}/media/{key}";
    }

    public void Dispose()
    {
        if (_disposed) return;
        _client?.Dispose();
        _disposed = true;
    }
}
