using Microsoft.AspNetCore.Mvc;
using UniMarket.Api.DTOs;
using UniMarket.Api.Services;

namespace UniMarket.Api.Controllers;

[ApiController]
[Route("api/uploads")]
public class UploadsController(
    CurrentUserService currentUser,
    R2StorageService storage) : ControllerBase
{
    private static readonly HashSet<string> AllowedContentTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        "image/jpeg",
        "image/jpg",
        "image/png",
        "image/webp",
        "image/heic",
        "image/heif",
    };

    [HttpPost("listing-photos")]
    [RequestSizeLimit(12 * 1024 * 1024)]
    public async Task<ActionResult<UploadPhotoResponse>> UploadListingPhoto(
        IFormFile file,
        CancellationToken ct) =>
        await UploadImageAsync(file, "Photo", storage.UploadListingPhotoAsync, ct);

    [HttpPost("seller-documents")]
    [RequestSizeLimit(12 * 1024 * 1024)]
    public async Task<ActionResult<UploadPhotoResponse>> UploadSellerDocument(
        IFormFile file,
        CancellationToken ct) =>
        await UploadImageAsync(file, "Student ID", storage.UploadSellerDocumentAsync, ct);

    private async Task<ActionResult<UploadPhotoResponse>> UploadImageAsync(
        IFormFile file,
        string label,
        Func<Stream, string, string, CancellationToken, Task<string>> upload,
        CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();

        if (!storage.IsConfigured)
        {
            return StatusCode(503, new { message = "Image upload is not configured on the server." });
        }

        if (file.Length == 0)
        {
            return BadRequest(new { message = $"Choose a {label.ToLowerInvariant()} image to upload." });
        }

        if (file.Length > 10 * 1024 * 1024)
        {
            return BadRequest(new { message = $"{label} must be 10 MB or smaller." });
        }

        var contentType = string.IsNullOrWhiteSpace(file.ContentType)
            ? "image/jpeg"
            : file.ContentType;

        if (!AllowedContentTypes.Contains(contentType))
        {
            return BadRequest(new { message = "Only JPG, PNG, and WEBP photos are supported." });
        }

        await using var stream = file.OpenReadStream();
        var url = await upload(
            stream,
            contentType,
            currentUser.UserId!,
            ct);

        return Ok(new UploadPhotoResponse(url));
    }
}
