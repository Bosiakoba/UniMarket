using Amazon.Runtime;
using Amazon.S3;
using Amazon.S3.Model;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using UniMarket.Api.Configuration;

namespace UniMarket.Api.Services;

public class R2StorageService : IDisposable
{
    private readonly CloudflareSettings _settings;
    private readonly ApiSettings _apiSettings;
    private readonly string _localUploadRoot;
    private readonly ILogger<R2StorageService> _logger;
    private IAmazonS3? _client;
    private bool _disposed;

    public R2StorageService(
        IOptions<CloudflareSettings> settings,
        IOptions<ApiSettings> apiSettings,
        IWebHostEnvironment environment,
        ILogger<R2StorageService> logger)
    {
        _settings = settings.Value;
        _apiSettings = apiSettings.Value;
        _localUploadRoot = Path.Combine(environment.ContentRootPath, "data", "uploads");
        _logger = logger;
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

        return BuildPublicMediaUrl(key);
    }

    public string BuildPublicMediaUrl(string key) =>
        $"{_apiSettings.PublicBaseUrl.Trim().TrimEnd('/')}/media/{key.TrimStart('/')}";

    /// <summary>
    /// Rewrites legacy direct R2 URLs to API-proxied /media/ URLs.
    /// </summary>
    public string NormalizeMediaUrl(string? url)
    {
        if (string.IsNullOrWhiteSpace(url))
        {
            return string.Empty;
        }

        var trimmed = url.Trim();
        if (TryExtractObjectKey(trimmed, out var key))
        {
            return BuildPublicMediaUrl(key);
        }

        return trimmed;
    }

    public async Task DeleteByUrlAsync(string? url, CancellationToken ct)
    {
        if (!CanUpload || string.IsNullOrWhiteSpace(url))
        {
            return;
        }

        if (!TryExtractObjectKey(url, out var key))
        {
            return;
        }

        await DeleteObjectAsync(key, ct);
    }

    public async Task DeleteByUrlsAsync(IEnumerable<string?> urls, CancellationToken ct)
    {
        foreach (var url in urls)
        {
            await DeleteByUrlAsync(url, ct);
        }
    }

    private async Task DeleteObjectAsync(string key, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(key))
        {
            return;
        }

        if (UsesLocalFallback || !IsR2Configured)
        {
            var filePath = Path.Combine(
                _localUploadRoot,
                key.Replace('/', Path.DirectorySeparatorChar));
            if (File.Exists(filePath))
            {
                File.Delete(filePath);
            }

            return;
        }

        try
        {
            await Client.DeleteObjectAsync(
                new DeleteObjectRequest
                {
                    BucketName = _settings.R2BucketName,
                    Key = key,
                },
                ct);
        }
        catch (AmazonS3Exception ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            // Already removed.
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to delete object {ObjectKey} from storage.", key);
        }
    }

    public async Task<(Stream Stream, string ContentType)?> TryOpenMediaAsync(
        string objectPath,
        CancellationToken ct)
    {
        var key = objectPath.Trim().TrimStart('/');
        if (string.IsNullOrWhiteSpace(key))
        {
            return null;
        }

        if (UsesLocalFallback || !IsR2Configured)
        {
            var filePath = Path.Combine(
                _localUploadRoot,
                key.Replace('/', Path.DirectorySeparatorChar));
            if (!File.Exists(filePath))
            {
                return null;
            }

            return (File.OpenRead(filePath), ContentTypeForPath(filePath));
        }

        try
        {
            var response = await Client.GetObjectAsync(
                new GetObjectRequest
                {
                    BucketName = _settings.R2BucketName,
                    Key = key,
                },
                ct);

            var contentType = string.IsNullOrWhiteSpace(response.Headers.ContentType)
                ? ContentTypeForPath(key)
                : response.Headers.ContentType;

            return (response.ResponseStream, contentType);
        }
        catch (AmazonS3Exception ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
        {
            return null;
        }
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

    public async Task<(Stream Stream, string ContentType)?> TryOpenDocumentAsync(
        string idDocumentUrl,
        CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(idDocumentUrl))
        {
            return null;
        }

        if (!TryResolveObjectKey(idDocumentUrl, out var key))
        {
            return null;
        }

        return await TryOpenMediaAsync(key, ct);
    }

    public bool TryResolveObjectKey(string idDocumentUrl, out string key) =>
        TryExtractObjectKey(idDocumentUrl, out key) &&
        key.StartsWith("seller-documents/", StringComparison.OrdinalIgnoreCase);

    private bool TryExtractObjectKey(string url, out string key)
    {
        key = string.Empty;
        if (!Uri.TryCreate(url, UriKind.Absolute, out var uri))
        {
            return false;
        }

        var path = uri.AbsolutePath.TrimStart('/');
        if (path.StartsWith("media/", StringComparison.OrdinalIgnoreCase))
        {
            path = path["media/".Length..];
        }

        if (path.StartsWith("listings/", StringComparison.OrdinalIgnoreCase) ||
            path.StartsWith("seller-documents/", StringComparison.OrdinalIgnoreCase))
        {
            key = path;
            return true;
        }

        foreach (var marker in new[] { "listings/", "seller-documents/" })
        {
            var markerIndex = path.IndexOf(marker, StringComparison.OrdinalIgnoreCase);
            if (markerIndex >= 0)
            {
                key = path[markerIndex..];
                return key.Length > marker.Length;
            }
        }

        return false;
    }

    private static string ContentTypeForPath(string path) =>
        Path.GetExtension(path).ToLowerInvariant() switch
        {
            ".png" => "image/png",
            ".webp" => "image/webp",
            ".heic" => "image/heic",
            ".heif" => "image/heif",
            _ => "image/jpeg",
        };

    public void Dispose()
    {
        if (_disposed) return;
        _client?.Dispose();
        _disposed = true;
    }
}
