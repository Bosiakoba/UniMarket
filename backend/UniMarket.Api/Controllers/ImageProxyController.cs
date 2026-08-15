using Microsoft.AspNetCore.Mvc;
using SkiaSharp;

namespace UniMarket.Api.Controllers;

[ApiController]
[Route("api/image-proxy")]
public class ImageProxyController : ControllerBase
{
    private static readonly HashSet<string> AllowedContentTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        "image/jpeg",
        "image/jpg",
        "image/png",
        "image/webp",
        "image/gif",
        "image/avif",
    };

    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ILogger<ImageProxyController> _logger;

    public ImageProxyController(IHttpClientFactory httpClientFactory, ILogger<ImageProxyController> logger)
    {
        _httpClientFactory = httpClientFactory;
        _logger = logger;
    }

    [HttpGet]
    [ResponseCache(Duration = 86400 * 7, Location = ResponseCacheLocation.Any)]
    public async Task<IActionResult> Proxy(
        [FromQuery] string url,
        [FromQuery] int w = 400,
        CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(url))
        {
            return BadRequest(new { message = "url is required." });
        }

        if (!Uri.TryCreate(url, UriKind.Absolute, out var uri) ||
            (uri.Scheme != "http" && uri.Scheme != "https"))
        {
            return BadRequest(new { message = "Invalid or unsupported URL." });
        }

        // Clamp width to a reasonable range
        var targetWidth = Math.Clamp(w, 50, 1920);

        try
        {
            using var client = _httpClientFactory.CreateClient();
            client.Timeout = TimeSpan.FromSeconds(20);
            // Some hosts (notably Wikimedia/Wikipedia and many CDNs) reject
            // requests without a descriptive User-Agent, returning 403.
            if (!client.DefaultRequestHeaders.UserAgent.Any())
            {
                client.DefaultRequestHeaders.UserAgent.TryParseAdd(
                    "UniMarket-App/1.0 (https://unimarket-alpha-vert.vercel.app)");
            }
            var response = await client.GetAsync(uri, ct);
            if (!response.IsSuccessStatusCode)
            {
                return BadRequest(new { message = $"Failed to fetch image: {response.StatusCode}" });
            }

            var contentType = response.Content.Headers.ContentType?.ToString() ?? "image/jpeg";
            if (!AllowedContentTypes.Contains(contentType))
            {
                return BadRequest(new { message = $"Unsupported content type: {contentType}" });
            }

            var imageBytes = await response.Content.ReadAsByteArrayAsync(ct);

            // Decode, resize, and encode the image
            using var inputStream = new SKMemoryStream(imageBytes);
            using var original = SKBitmap.Decode(inputStream);
            if (original == null)
            {
                return BadRequest(new { message = "Could not decode image." });
            }

            // Only resize if the image is larger than the target width
            if (original.Width > targetWidth)
            {
                var ratio = (double)targetWidth / original.Width;
                var targetHeight = (int)(original.Height * ratio);

                using var resized = original.Resize(new SKImageInfo(targetWidth, targetHeight), new SKSamplingOptions());
                if (resized == null)
                {
                    return BadRequest(new { message = "Could not resize image." });
                }

                // Encode as JPEG (universally supported, good compression)
                using var image = SKImage.FromBitmap(resized);
                var encoded = image.Encode(SKEncodedImageFormat.Jpeg, 80);

                return File(encoded.ToArray(), "image/jpeg");
            }

            // Image is already small enough — return as-is
            return File(imageBytes, contentType);
        }
        catch (OperationCanceledException)
        {
            return StatusCode(504, new { message = "Image fetch timed out." });
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Image proxy failed for {Url}", url);
            return StatusCode(502, new { message = "Image proxy failed." });
        }
    }
}
