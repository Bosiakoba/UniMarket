using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using UniMarket.Api.Configuration;
using UniMarket.Api.Data;
using UniMarket.Api.DTOs;
using UniMarket.Api.Models;
using UniMarket.Api.Services;

namespace UniMarket.Api.Controllers;

[ApiController]
[Route("api/admin")]
public class AdminController(
    AppDbContext db,
    ResendEmailService emailService,
    NotificationService notifications,
    IOptions<AdminSettings> adminSettings) : ControllerBase
{
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

    [HttpGet("reports")]
    public async Task<ActionResult<IEnumerable<AdminReportDto>>> GetReports(CancellationToken ct)
    {
        if (!IsAuthorized()) return Unauthorized();

        var reports = await db.ListingReports
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync(ct);

        var listingIds = reports.Select(r => r.ListingId).Distinct().ToList();
        var listings = await db.Listings
            .Where(l => listingIds.Contains(l.Id))
            .ToDictionaryAsync(l => l.Id, l => l.Title, ct);

        var reporterIds = reports.Select(r => r.ReporterUserId).Distinct().ToList();
        var reporters = await db.Users
            .Where(u => reporterIds.Contains(u.Id))
            .ToDictionaryAsync(u => u.Id, u => u.FullName, ct);

        var result = reports.Select(r => new AdminReportDto(
            r.Id,
            r.ListingId,
            listings.GetValueOrDefault(r.ListingId, "Unknown Listing"),
            r.ReporterUserId,
            reporters.GetValueOrDefault(r.ReporterUserId, "Unknown User"),
            r.Reason,
            r.Comment ?? string.Empty,
            r.Status,
            r.CreatedAt
        )).ToList();

        return Ok(result);
    }

    [HttpPost("reports/{id}/resolve")]
    public async Task<IActionResult> ResolveReport(string id, CancellationToken ct)
    {
        if (!IsAuthorized()) return Unauthorized();

        var report = await db.ListingReports.FindAsync([id], ct);
        if (report is null) return NotFound();

        report.Status = "Resolved";
        await db.SaveChangesAsync(ct);

        return NoContent();
    }

    [HttpGet("users")]
    public async Task<ActionResult<IEnumerable<AdminUserDto>>> GetUsers(CancellationToken ct)
    {
        if (!IsAuthorized()) return Unauthorized();

        var users = await db.Users
            .Where(u => !u.Email.EndsWith("@university.edu"))
            .OrderByDescending(u => u.CreatedAt)
            .Select(u => new AdminUserDto(
                u.Id,
                u.FullName,
                u.Email,
                u.Role,
                u.IsSeller,
                u.IsVerified,
                u.IsSuspended,
                u.CreatedAt
            ))
            .ToListAsync(ct);

        return Ok(users);
    }

    [HttpPost("users/{id}/suspend")]
    public async Task<IActionResult> SuspendUser(string id, [FromQuery] string? reason, CancellationToken ct)
    {
        if (!IsAuthorized()) return Unauthorized();

        var user = await db.Users.FindAsync([id], ct);
        if (user is null) return NotFound();

        user.IsSuspended = true;
        await db.SaveChangesAsync(ct);

        try
        {
            await emailService.SendAccountSuspendedEmailAsync(user.Email, user.FullName, reason, ct);
        }
        catch
        {
            // Non-blocking email alert
        }

        return NoContent();
    }

    [HttpPost("users/{id}/unsuspend")]
    public async Task<IActionResult> UnsuspendUser(string id, CancellationToken ct)
    {
        if (!IsAuthorized()) return Unauthorized();

        var user = await db.Users.FindAsync([id], ct);
        if (user is null) return NotFound();

        user.IsSuspended = false;
        await db.SaveChangesAsync(ct);

        try
        {
            await emailService.SendAccountUnsuspendedEmailAsync(user.Email, user.FullName, ct);
        }
        catch
        {
            // Non-blocking email alert
        }

        return NoContent();
    }

    [HttpGet("listings")]
    public async Task<ActionResult<IEnumerable<object>>> GetListings(CancellationToken ct)
    {
        if (!IsAuthorized()) return Unauthorized();

        var listings = await db.Listings
            .Include(l => l.Owner)
            .OrderByDescending(l => l.CreatedAt)
            .Select(l => new
            {
                l.Id,
                l.Title,
                l.Price,
                l.Status,
                l.Views,
                l.CreatedAt,
                l.AppealComment,
                SellerName = l.Owner != null ? l.Owner.FullName : "Unknown",
                SellerEmail = l.Owner != null ? l.Owner.Email : "Unknown"
            })
            .ToListAsync(ct);

        return Ok(listings);
    }

    [HttpPost("listings/{id}/suspend")]
    public async Task<IActionResult> SuspendListing(string id, [FromQuery] string? reason, CancellationToken ct)
    {
        if (!IsAuthorized()) return Unauthorized();

        var listing = await db.Listings.Include(l => l.Owner).FirstOrDefaultAsync(l => l.Id == id, ct);
        if (listing is null) return NotFound();

        listing.Status = "suspended";
        await db.SaveChangesAsync(ct);

        if (listing.Owner != null)
        {
            // Create user notification (FCM + DB list)
            await notifications.CreateAsync(
                listing.UserId,
                "Listing suspended",
                $"Your listing '{listing.Title}' has been suspended for violating campus guidelines.",
                "listingSuspended",
                listing.Id,
                "View guidelines",
                ct);

            // Send email alert
            try
            {
                await emailService.SendListingSuspendedEmailAsync(
                    listing.Owner.Email,
                    listing.Owner.FullName,
                    listing.Title,
                    reason,
                    ct);
            }
            catch
            {
                // Non-blocking email alert
            }
        }

        return NoContent();
    }

    [HttpPost("listings/{id}/unsuspend")]
    public async Task<IActionResult> UnsuspendListing(string id, CancellationToken ct)
    {
        if (!IsAuthorized()) return Unauthorized();

        var listing = await db.Listings.Include(l => l.Owner).FirstOrDefaultAsync(l => l.Id == id, ct);
        if (listing is null) return NotFound();

        listing.Status = "active";
        listing.AppealComment = null; // Clear the appeal comment
        await db.SaveChangesAsync(ct);

        if (listing.Owner != null)
        {
            try
            {
                await emailService.SendListingUnsuspendedEmailAsync(
                    listing.Owner.Email,
                    listing.Owner.FullName,
                    listing.Title,
                    ct);
            }
            catch
            {
                // Non-blocking email alert
            }
        }

        return NoContent();
    }

    [HttpPost("campaigns/send")]
    public async Task<IActionResult> SendCampaign([FromBody] CampaignRequest request, CancellationToken ct)
    {
        if (!IsAuthorized()) return Unauthorized();

        var users = await db.Users
            .Where(u => !u.IsSuspended && !u.Email.EndsWith("@university.edu"))
            .ToListAsync(ct);

        foreach (var user in users)
        {
            try
            {
                await emailService.SendCampaignEmailAsync(user.Email, user.FullName, request.Subject, request.HtmlBody, ct);
            }
            catch
            {
                // Continue sending campaign to other users even if one fails
            }
        }

        return Ok(new { sentCount = users.Count });
    }

    [HttpPost("nuke-all-data")]
    public async Task<IActionResult> NukeAllData(
        [FromServices] D1Client d1,
        CancellationToken ct)
    {
        D1SaveChangesInterceptor.SuppressSync = true;
        try
        {
            var tables = new[]
            {
                "ListingViews", "ListingReports", "ListingReviews", "WishlistItems",
                "ListingImages", "Listings", "Messages", "Chats", "SaleConfirmations",
                "SaleRecords", "UserFollows", "DeviceRegistrations", "UserNotifications",
                "CampusEmailOtps", "VerificationRequests"
            };

            foreach (var table in tables)
            {
                await db.Database.ExecuteSqlRawAsync($"DELETE FROM {table};", ct);
            }
            await db.Database.ExecuteSqlRawAsync("DELETE FROM Users WHERE Email LIKE '%@university.edu' OR Id = 'alex-demo' OR Id = 'seller-jordan';", ct);
            await db.SaveChangesAsync(ct);

            if (d1.IsConfigured)
            {
                foreach (var table in tables)
                {
                    await d1.QueryAsync($"DELETE FROM {table};", null, ct);
                }
                await d1.QueryAsync("DELETE FROM Users WHERE Email LIKE '%@university.edu' OR Id = 'alex-demo' OR Id = 'seller-jordan';", null, ct);
            }

            return Ok(new { message = "Database cleaned successfully. All listings, chats, and mock users have been wiped." });
        }
        finally
        {
            D1SaveChangesInterceptor.SuppressSync = false;
        }
    }

    [HttpGet("carousel-banners")]
    public async Task<ActionResult<IEnumerable<CarouselBannerDto>>> GetCarouselBanners(CancellationToken ct)
    {
        if (!IsAuthorized()) return Unauthorized();

        var banners = await db.CarouselBanners
            .OrderByDescending(b => b.CreatedAt)
            .ToListAsync(ct);

        return Ok(banners.Select(b => new CarouselBannerDto(
            b.Id,
            b.Title,
            b.Subtitle,
            b.ImageUrl,
            b.RoutePath,
            b.CreatedAt)));
    }

    [HttpPost("carousel-banners")]
    public async Task<ActionResult<CarouselBannerDto>> CreateCarouselBanner(
        [FromBody] CreateCarouselBannerRequest request,
        CancellationToken ct)
    {
        if (!IsAuthorized()) return Unauthorized();

        if (string.IsNullOrWhiteSpace(request.Title) || string.IsNullOrWhiteSpace(request.ImageUrl))
        {
            return BadRequest(new { message = "Title and ImageUrl are required." });
        }

        var banner = new CarouselBanner
        {
            Id = Guid.NewGuid().ToString("N")[..12],
            Title = request.Title.Trim(),
            Subtitle = request.Subtitle ?? string.Empty,
            ImageUrl = request.ImageUrl.Trim(),
            RoutePath = request.RoutePath ?? string.Empty,
            CreatedAt = DateTime.UtcNow
        };

        db.CarouselBanners.Add(banner);
        await db.SaveChangesAsync(ct);

        return Ok(new CarouselBannerDto(
            banner.Id,
            banner.Title,
            banner.Subtitle,
            banner.ImageUrl,
            banner.RoutePath,
            banner.CreatedAt));
    }

    [HttpPut("carousel-banners/{id}")]
    public async Task<IActionResult> UpdateCarouselBanner(
        string id,
        [FromBody] CreateCarouselBannerRequest request,
        CancellationToken ct)
    {
        if (!IsAuthorized()) return Unauthorized();

        var banner = await db.CarouselBanners.FindAsync([id], ct);
        if (banner is null) return NotFound();

        if (string.IsNullOrWhiteSpace(request.Title) || string.IsNullOrWhiteSpace(request.ImageUrl))
        {
            return BadRequest(new { message = "Title and ImageUrl are required." });
        }

        banner.Title = request.Title.Trim();
        banner.Subtitle = request.Subtitle ?? string.Empty;
        banner.ImageUrl = request.ImageUrl.Trim();
        banner.RoutePath = request.RoutePath ?? string.Empty;

        await db.SaveChangesAsync(ct);
        return Ok(new CarouselBannerDto(
            banner.Id,
            banner.Title,
            banner.Subtitle,
            banner.ImageUrl,
            banner.RoutePath,
            banner.CreatedAt));
    }

    [HttpDelete("carousel-banners/{id}")]
    public async Task<IActionResult> DeleteCarouselBanner(string id, CancellationToken ct)
    {
        if (!IsAuthorized()) return Unauthorized();

        var banner = await db.CarouselBanners.FindAsync([id], ct);
        if (banner is null) return NotFound();

        db.CarouselBanners.Remove(banner);
        await db.SaveChangesAsync(ct);

        return Ok();
    }
}
