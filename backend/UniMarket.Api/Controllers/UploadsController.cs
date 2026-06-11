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
        CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();

        if (!storage.IsConfigured)
        {
            return StatusCode(503, new { message = "Image upload is not configured on the server." });
        }

        if (file.Length == 0)
        {
            return BadRequest(new { message = "Choose a photo to upload." });
        }

        if (file.Length > 10 * 1024 * 1024)
        {
            return BadRequest(new { message = "Photo must be 10 MB or smaller." });
        }

        var contentType = string.IsNullOrWhiteSpace(file.ContentType)
            ? "image/jpeg"
            : file.ContentType;

        if (!AllowedContentTypes.Contains(contentType))
        {
            return BadRequest(new { message = "Only JPG, PNG, and WEBP photos are supported." });
        }

        await using var stream = file.OpenReadStream();
        var url = await storage.UploadListingPhotoAsync(
            stream,
            contentType,
            currentUser.UserId!,
            ct);

        return Ok(new UploadPhotoResponse(url));
    }
}
