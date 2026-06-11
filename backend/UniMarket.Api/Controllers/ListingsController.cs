using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UniMarket.Api.Data;
using UniMarket.Api.DTOs;
using UniMarket.Api.Models;
using UniMarket.Api.Services;

namespace UniMarket.Api.Controllers;

[ApiController]
[Route("api/listings")]
public class ListingsController(
    AppDbContext db,
    CurrentUserService currentUser,
    ListingMapper mapper,
    SaleConfirmationService saleConfirmation) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<ListingDto>>> Search(
        [FromQuery] string? q,
        [FromQuery] string? category,
        [FromQuery] string sort = "verified",
        CancellationToken ct = default)
    {
        var query = db.Listings
            .Include(l => l.Images)
            .Include(l => l.Owner)
            .Where(l => l.Status == "active")
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(category) && category != "All")
        {
            query = query.Where(l => l.Category == category);
        }

        if (!string.IsNullOrWhiteSpace(q))
        {
            var term = q.Trim().ToLower();
            query = query.Where(l =>
                l.Title.ToLower().Contains(term) ||
                l.Category.ToLower().Contains(term) ||
                l.Description.ToLower().Contains(term) ||
                l.TagsJson.ToLower().Contains(term) ||
                l.AttributesJson.ToLower().Contains(term));
        }

        var listings = await query.ToListAsync(ct);

        listings = sort switch
        {
            "price_asc" => listings.OrderBy(l => l.Price).ToList(),
            "price_desc" => listings.OrderByDescending(l => l.Price).ToList(),
            "nearest" => listings.OrderBy(l => l.DistanceKm).ToList(),
            _ => listings
                .OrderByDescending(l => l.Owner != null && l.Owner.IsVerified)
                .ThenBy(l => l.DistanceKm)
                .ToList(),
        };

        var dtos = new List<ListingDto>();
        foreach (var listing in listings)
        {
            dtos.Add(await mapper.ToDtoAsync(listing, ct));
        }

        return Ok(dtos);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ListingDto>> GetById(string id, CancellationToken ct)
    {
        var listing = await db.Listings
            .Include(l => l.Images)
            .Include(l => l.Owner)
            .FirstOrDefaultAsync(l => l.Id == id, ct);

        return listing is null ? NotFound() : Ok(await mapper.ToDtoAsync(listing, ct));
    }

    [HttpPost]
    public async Task<ActionResult<ListingDto>> Create(
        [FromBody] CreateListingRequest request,
        CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();

        var user = await db.Users.FindAsync([currentUser.UserId!], ct);
        if (user is null) return NotFound();
        if (!user.IsSeller) return Forbid();

        if (!user.IsSeller)
        {
            user.IsSeller = true;
        }

        var id = Guid.NewGuid().ToString("N")[..12];
        var listing = new Listing
        {
            Id = id,
            UserId = user.Id,
            Title = request.Title.Trim(),
            Description = request.Description.Trim(),
            Price = request.Price,
            OriginalPrice = request.OriginalPrice,
            DiscountEndsAt = request.DiscountEndsAt,
            DiscountDurationDays = request.DiscountDurationDays,
            Category = request.Category,
            Condition = request.Condition,
            MeetupLocation = request.MeetupLocation,
            Status = "active",
            AvailabilityType = NormalizeAvailabilityType(request.AvailabilityType),
            QuantityAvailable = ResolveQuantityAvailable(
                request.AvailabilityType,
                request.QuantityAvailable),
            UnitsSold = 0,
            TagsJson = ListingMapper.SerializeTags(request.Tags),
            AttributesJson = ListingMapper.SerializeAttributes(request.Attributes),
            Owner = user,
        };

        for (var i = 0; i < request.PhotoUrls.Count; i++)
        {
            listing.Images.Add(new ListingImage
            {
                Id = $"{id}-img-{i}",
                ListingId = id,
                ImageUrl = request.PhotoUrls[i],
                SortOrder = i,
            });
        }

        db.Listings.Add(listing);
        await db.SaveChangesAsync(ct);
        return CreatedAtAction(nameof(GetById), new { id }, await mapper.ToDtoAsync(listing, ct));
    }

    [HttpPut("{id}")]
    public async Task<ActionResult<ListingDto>> Update(
        string id,
        [FromBody] CreateListingRequest request,
        CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();

        var listing = await db.Listings
            .Include(l => l.Images)
            .Include(l => l.Owner)
            .FirstOrDefaultAsync(l => l.Id == id, ct);

        if (listing is null) return NotFound();
        if (listing.UserId != currentUser.UserId) return Forbid();

        listing.Title = request.Title.Trim();
        listing.Description = request.Description.Trim();
        listing.Price = request.Price;
        listing.OriginalPrice = request.OriginalPrice;
        listing.DiscountEndsAt = request.DiscountEndsAt;
        listing.DiscountDurationDays = request.DiscountDurationDays;
        listing.Category = request.Category;
        listing.Condition = request.Condition;
        listing.MeetupLocation = request.MeetupLocation;
        listing.AvailabilityType = NormalizeAvailabilityType(request.AvailabilityType);
        listing.QuantityAvailable = ResolveQuantityAvailable(
            request.AvailabilityType,
            request.QuantityAvailable);
        listing.TagsJson = ListingMapper.SerializeTags(request.Tags);
        listing.AttributesJson = ListingMapper.SerializeAttributes(request.Attributes);

        db.ListingImages.RemoveRange(listing.Images);
        listing.Images.Clear();
        for (var i = 0; i < request.PhotoUrls.Count; i++)
        {
            listing.Images.Add(new ListingImage
            {
                Id = $"{id}-img-{i}",
                ListingId = id,
                ImageUrl = request.PhotoUrls[i],
                SortOrder = i,
            });
        }

        await db.SaveChangesAsync(ct);
        return Ok(await mapper.ToDtoAsync(listing, ct));
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(string id, CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();

        var listing = await db.Listings.FindAsync([id], ct);
        if (listing is null) return NotFound();
        if (listing.UserId != currentUser.UserId) return Forbid();

        db.Listings.Remove(listing);
        await db.SaveChangesAsync(ct);
        return NoContent();
    }

    [HttpPost("{id}/sales")]
    public async Task<ActionResult<SaleRecordDto>> RecordSale(
        string id,
        [FromBody] RecordSaleRequest request,
        CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();

        var listing = await db.Listings.FindAsync([id], ct);
        if (listing is null) return NotFound();
        if (listing.UserId != currentUser.UserId) return Forbid();

        var units = Math.Max(1, request.Units);
        var availability = listing.AvailabilityType;

        switch (availability)
        {
            case "ongoing":
                listing.UnitsSold += units;
                listing.Status = "active";
                break;
            case "stock":
                if (listing.QuantityAvailable is null or <= 0)
                {
                    return BadRequest("Listing is sold out. Restock before recording another sale.");
                }

                if (units > listing.QuantityAvailable)
                {
                    return BadRequest(
                        $"Only {listing.QuantityAvailable} unit(s) remain in stock.");
                }

                listing.QuantityAvailable -= units;
                listing.UnitsSold += units;
                if (listing.QuantityAvailable <= 0)
                {
                    listing.QuantityAvailable = 0;
                    listing.Status = "sold_out";
                }
                else
                {
                    listing.Status = "active";
                }
                break;
            default:
                if (units != 1)
                {
                    return BadRequest("Unique listings can only record one sale at a time.");
                }

                listing.UnitsSold = 1;
                listing.Status = "sold";
                break;
        }

        var sale = new SaleRecord
        {
            Id = Guid.NewGuid().ToString("N")[..12],
            ListingId = listing.Id,
            SellerId = listing.UserId,
            BuyerId = request.BuyerUserId,
            Units = units,
            Status = "seller_reported",
            CreatedAt = DateTime.UtcNow,
        };

        db.SaleRecords.Add(sale);
        await db.SaveChangesAsync(ct);
        await saleConfirmation.NotifyListingEnquirersAsync(listing, sale, ct);

        return Ok(new SaleRecordDto(
            sale.Id,
            sale.ListingId,
            listing.Title,
            sale.Units,
            sale.Status,
            sale.CreatedAt,
            listing.QuantityAvailable,
            listing.Status));
    }

    [HttpPost("{id}/restock")]
    public async Task<ActionResult<ListingDto>> Restock(
        string id,
        [FromBody] RestockRequest request,
        CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();

        var listing = await db.Listings
            .Include(l => l.Images)
            .Include(l => l.Owner)
            .FirstOrDefaultAsync(l => l.Id == id, ct);

        if (listing is null) return NotFound();
        if (listing.UserId != currentUser.UserId) return Forbid();
        if (listing.AvailabilityType != "stock")
        {
            return BadRequest("Only stock listings can be restocked.");
        }

        var quantity = Math.Max(1, request.Quantity);
        listing.QuantityAvailable = (listing.QuantityAvailable ?? 0) + quantity;
        listing.Status = "active";
        await db.SaveChangesAsync(ct);

        return Ok(await mapper.ToDtoAsync(listing, ct));
    }

    [HttpPost("{id}/relist")]
    public async Task<ActionResult<ListingDto>> Relist(string id, CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();

        var listing = await db.Listings
            .Include(l => l.Images)
            .Include(l => l.Owner)
            .FirstOrDefaultAsync(l => l.Id == id, ct);

        if (listing is null) return NotFound();
        if (listing.UserId != currentUser.UserId) return Forbid();
        if (listing.AvailabilityType != "unique")
        {
            return BadRequest("Only unique listings can be relisted this way.");
        }

        listing.Status = "active";
        listing.UnitsSold = 0;
        await db.SaveChangesAsync(ct);
        return Ok(await mapper.ToDtoAsync(listing, ct));
    }

    [HttpPost("{id}/sold")]
    public async Task<ActionResult<SaleRecordDto>> MarkSold(string id, CancellationToken ct) =>
        await RecordSale(id, new RecordSaleRequest(1), ct);

    [HttpPost("{id}/active")]
    public async Task<IActionResult> MarkActive(string id, CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();

        var listing = await db.Listings
            .Include(l => l.Images)
            .Include(l => l.Owner)
            .FirstOrDefaultAsync(l => l.Id == id, ct);

        if (listing is null) return NotFound();
        if (listing.UserId != currentUser.UserId) return Forbid();

        listing.Status = "active";
        if (listing.AvailabilityType == "unique")
        {
            listing.UnitsSold = 0;
        }

        await db.SaveChangesAsync(ct);
        return Ok(await mapper.ToDtoAsync(listing, ct));
    }

    private static string NormalizeAvailabilityType(string? value) =>
        value switch
        {
            "stock" => "stock",
            "ongoing" => "ongoing",
            _ => "unique",
        };

    private static int? ResolveQuantityAvailable(string? availabilityType, int? quantity)
    {
        if (availabilityType != "stock") return null;
        return Math.Max(2, quantity ?? 2);
    }
}
