using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UniMarket.Api.Data;
using UniMarket.Api.DTOs;
using UniMarket.Api.Models;
using UniMarket.Api.Services;

namespace UniMarket.Api.Controllers;

[ApiController]
[Route("api/listings/{listingId}/reviews")]
public class ReviewsController(AppDbContext db, CurrentUserService currentUser) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<ListingReviewDto>>> List(
        string listingId,
        CancellationToken ct)
    {
        var reviews = await db.ListingReviews
            .Where(r => r.ListingId == listingId)
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync(ct);

        return Ok(reviews.Select(ToDto));
    }

    [HttpPost]
    public async Task<ActionResult<ListingReviewDto>> Create(
        string listingId,
        [FromBody] CreateReviewRequest request,
        CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();
        if (request.Score is < 1 or > 5) return BadRequest();

        var listingExists = await db.Listings.AnyAsync(l => l.Id == listingId, ct);
        if (!listingExists) return NotFound();

        var user = await db.Users.FindAsync([currentUser.UserId!], ct);
        var review = new ListingReview
        {
            Id = Guid.NewGuid().ToString("N"),
            ListingId = listingId,
            AuthorUserId = currentUser.UserId!,
            AuthorName = user?.FullName ?? "Campus buyer",
            Score = request.Score,
            Comment = request.Comment.Trim(),
        };

        db.ListingReviews.Add(review);
        await db.SaveChangesAsync(ct);
        return Ok(ToDto(review));
    }

    private static ListingReviewDto ToDto(ListingReview review) =>
        new(
            review.Id,
            review.AuthorName,
            review.Score,
            review.Comment,
            FormatDate(review.CreatedAt));

    private static string FormatDate(DateTime createdAt)
    {
        var delta = DateTime.UtcNow - createdAt;
        if (delta.TotalMinutes < 2) return "Just now";
        if (delta.TotalHours < 24) return $"{(int)delta.TotalHours}h ago";
        return $"{(int)delta.TotalDays}d ago";
    }
}
