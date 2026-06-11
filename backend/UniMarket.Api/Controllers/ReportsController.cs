using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UniMarket.Api.Data;
using UniMarket.Api.DTOs;
using UniMarket.Api.Models;
using UniMarket.Api.Services;

namespace UniMarket.Api.Controllers;

[ApiController]
[Route("api/reports")]
public class ReportsController(AppDbContext db, CurrentUserService currentUser) : ControllerBase
{
    [HttpGet("mine")]
    public async Task<ActionResult<IEnumerable<object>>> Mine(CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();

        var reports = await db.ListingReports
            .Where(r => r.ReporterUserId == currentUser.UserId)
            .OrderByDescending(r => r.CreatedAt)
            .Select(r => new
            {
                r.Id,
                r.ListingId,
                r.Reason,
                r.Comment,
                r.Status,
                r.CreatedAt,
            })
            .ToListAsync(ct);

        return Ok(reports);
    }

    [HttpPost("listings/{listingId}")]
    public async Task<IActionResult> ReportListing(
        string listingId,
        [FromBody] ReportListingRequest request,
        CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();

        var listing = await db.Listings.FindAsync([listingId], ct);
        if (listing is null) return NotFound();

        db.ListingReports.Add(new ListingReport
        {
            Id = Guid.NewGuid().ToString("N"),
            ListingId = listingId,
            ReporterUserId = currentUser.UserId!,
            Reason = request.Reason.Trim(),
            Comment = request.Comment?.Trim(),
        });

        await db.SaveChangesAsync(ct);
        return Ok(new { status = "Pending" });
    }
}
