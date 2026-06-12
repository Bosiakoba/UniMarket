using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using UniMarket.Api.Configuration;
using UniMarket.Api.DTOs;
using UniMarket.Api.Services;

namespace UniMarket.Api.Controllers;

[ApiController]
[Route("api/admin/verification-requests")]
public class AdminVerificationController(
    VerificationQueueService queue,
    R2StorageService storage,
    IOptions<AdminSettings> adminSettings) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IReadOnlyList<VerificationRequestDto>>> List(
        [FromQuery] string? status,
        [FromQuery] string? type,
        CancellationToken ct)
    {
        if (!IsAuthorized()) return Unauthorized();

        if (!string.IsNullOrWhiteSpace(type) &&
            !VerificationQueueService.AllowedTypes.Contains(type))
        {
            return BadRequest(new { message = "Invalid request type." });
        }

        var items = await queue.ListQueueAsync(status, type, ct);
        return Ok(items);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<VerificationRequestDto>> Get(string id, CancellationToken ct)
    {
        if (!IsAuthorized()) return Unauthorized();

        var item = await queue.GetAsync(id, ct);
        return item is null ? NotFound() : Ok(item);
    }

    [HttpPost("{id}/approve")]
    public async Task<ActionResult<VerificationRequestDto>> Approve(string id, CancellationToken ct)
    {
        if (!IsAuthorized()) return Unauthorized();

        try
        {
            return Ok(await queue.ApproveAsync(id, ct));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("{id}/reject")]
    public async Task<ActionResult<VerificationRequestDto>> Reject(
        string id,
        [FromBody] AdminRejectRequest request,
        CancellationToken ct)
    {
        if (!IsAuthorized()) return Unauthorized();

        try
        {
            return Ok(await queue.RejectAsync(id, request.Notes, ct));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("{id}/id-document")]
    public async Task<IActionResult> GetIdDocument(string id, CancellationToken ct)
    {
        if (!IsAuthorized()) return Unauthorized();

        var item = await queue.GetAsync(id, ct);
        if (item is null || string.IsNullOrWhiteSpace(item.IdDocumentUrl))
        {
            return NotFound();
        }

        var opened = await storage.TryOpenDocumentAsync(item.IdDocumentUrl, ct);
        if (opened is null)
        {
            return NotFound(new { message = "ID document file is not available on the server." });
        }

        return File(opened.Value.Stream, opened.Value.ContentType);
    }

    [HttpPost("{id}/ai-review")]
    public async Task<ActionResult<VerificationRequestDto>> SaveAiReview(
        string id,
        [FromBody] AdminAiReviewRequest request,
        CancellationToken ct)
    {
        if (!IsAuthorized()) return Unauthorized();

        if (string.IsNullOrWhiteSpace(request.Summary))
        {
            return BadRequest(new { message = "Summary is required." });
        }

        try
        {
            return Ok(await queue.SaveAiReviewAsync(
                id,
                request.Summary,
                request.Recommendation,
                ct));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    private bool IsAuthorized()
    {
        var configured = adminSettings.Value;
        if (!configured.IsConfigured) return false;

        if (!Request.Headers.TryGetValue("X-Admin-Key", out var provided))
        {
            return false;
        }

        return string.Equals(
            provided.ToString(),
            configured.ApiKey,
            StringComparison.Ordinal);
    }
}
