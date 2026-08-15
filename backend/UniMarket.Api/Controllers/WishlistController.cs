using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UniMarket.Api.Data;
using UniMarket.Api.DTOs;
using UniMarket.Api.Models;
using UniMarket.Api.Services;

namespace UniMarket.Api.Controllers;

[ApiController]
[Route("api/wishlist")]
public class WishlistController(
    AppDbContext db,
    CurrentUserService currentUser,
    ListingMapper mapper) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<ListingDto>>> Get(CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();

        var ids = await db.WishlistItems
            .Where(w => w.UserId == currentUser.UserId)
            .Select(w => w.ListingId)
            .ToListAsync(ct);

        var listings = await db.Listings
            .Include(l => l.Images)
            .Include(l => l.Owner)
            .Where(l => ids.Contains(l.Id))
            .ToListAsync(ct);

        var dtos = new List<ListingDto>();
        foreach (var listing in listings)
        {
            dtos.Add(await mapper.ToDtoAsync(listing, ct));
        }

        return Ok(dtos);
    }

    [HttpPost("{listingId}")]
    public async Task<IActionResult> Add(string listingId, CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();

        var exists = await db.Listings.AnyAsync(l => l.Id == listingId, ct);
        if (!exists) return NotFound();

        var saved = await db.WishlistItems.FindAsync([currentUser.UserId!, listingId], ct);
        if (saved is null)
        {
            db.WishlistItems.Add(new WishlistItem
            {
                UserId = currentUser.UserId!,
                ListingId = listingId,
            });
            await db.SaveChangesAsync(ct);
        }

        return Ok();
    }

    [HttpDelete("{listingId}")]
    public async Task<IActionResult> Remove(string listingId, CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();

        var item = await db.WishlistItems.FindAsync([currentUser.UserId!, listingId], ct);
        if (item is null) return NotFound();

        db.WishlistItems.Remove(item);
        await db.SaveChangesAsync(ct);
        return NoContent();
    }
}
