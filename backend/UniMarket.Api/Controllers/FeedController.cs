using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UniMarket.Api.Data;
using UniMarket.Api.DTOs;
using UniMarket.Api.Services;

namespace UniMarket.Api.Controllers;

[ApiController]
[Route("api/feed")]
public class FeedController(
    AppDbContext db,
    ListingMapper mapper,
    CurrentUserService currentUser) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<ListingDto>>> GetFeed(CancellationToken ct)
    {
        var currentUserId = currentUser.UserId;
        var user = currentUserId != null ? await db.Users.FindAsync([currentUserId], ct) : null;
        var userCampus = user?.Campus ?? "";
        var userUniversity = user?.University ?? "";
        var followingIds = currentUserId != null 
            ? await db.UserFollows.Where(f => f.FollowerId == currentUserId).Select(f => f.FolloweeId).ToListAsync(ct)
            : new List<string>();

        var query = db.Listings
            .Include(l => l.Images)
            .Include(l => l.Owner)
            .Where(l => l.Status == "active")
            .OrderByDescending(l => followingIds.Contains(l.UserId) ? 5 :
                (l.Owner!.IsVerified && l.Owner.Campus == userCampus) ? 4 :
                (l.Owner!.IsVerified && l.Owner.University == userUniversity) ? 3 :
                (l.Owner!.Campus == userCampus || l.Owner.University == userUniversity) ? 2 :
                1)
            .ThenByDescending(l => l.CreatedAt);

        var listings = await query.ToListAsync(ct);
        var result = new List<ListingDto>();
        foreach (var item in listings)
        {
            result.Add(await mapper.ToDtoAsync(item, ct));
        }

        return Ok(result);
    }

    [HttpGet("carousel-banners")]
    public async Task<ActionResult<IEnumerable<CarouselBannerDto>>> GetCarouselBanners(CancellationToken ct)
    {
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
}
