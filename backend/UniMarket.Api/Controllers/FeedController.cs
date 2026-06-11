using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UniMarket.Api.Data;
using UniMarket.Api.DTOs;
using UniMarket.Api.Services;

namespace UniMarket.Api.Controllers;

[ApiController]
[Route("api/feed")]
public class FeedController(AppDbContext db, ListingMapper mapper) : ControllerBase
{
    [HttpGet("home")]
    public async Task<ActionResult<IEnumerable<FeedSectionDto>>> Home(CancellationToken ct)
    {
        var listings = await db.Listings
            .Include(l => l.Images)
            .Include(l => l.Owner)
            .Where(l => l.Status == "active")
            .ToListAsync(ct);

        async Task<IReadOnlyList<ListingDto>> Map(IEnumerable<Models.Listing> source)
        {
            var result = new List<ListingDto>();
            foreach (var item in source)
            {
                result.Add(await mapper.ToDtoAsync(item, ct));
            }
            return result;
        }

        var hotDeals = listings
            .Where(l => l.OriginalPrice.HasValue && l.DiscountEndsAt > DateTime.UtcNow)
            .Take(6);

        var verified = listings
            .Where(l => l.Owner?.IsVerified == true)
            .Take(6);

        var nearYou = listings
            .OrderBy(l => l.DistanceKm)
            .Take(6);

        var trending = listings
            .OrderByDescending(l => l.CreatedAt)
            .Take(6);

        return Ok(new[]
        {
            new FeedSectionDto("hot_deals", "Hot deals", await Map(hotDeals)),
            new FeedSectionDto("verified", "Verified sellers", await Map(verified)),
            new FeedSectionDto("near_you", "Near you", await Map(nearYou)),
            new FeedSectionDto("trending", "Trending on campus", await Map(trending)),
        });
    }
}
