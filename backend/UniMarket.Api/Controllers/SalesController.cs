using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UniMarket.Api.Data;
using UniMarket.Api.DTOs;
using UniMarket.Api.Models;
using UniMarket.Api.Services;

namespace UniMarket.Api.Controllers;

[ApiController]
[Route("api/sales")]
public class SalesController(AppDbContext db, CurrentUserService currentUser) : ControllerBase
{
    [HttpPost("{saleId}/confirm")]
    public async Task<ActionResult<SaleRecordDto>> Confirm(string saleId, CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();

        var sale = await db.SaleRecords
            .Include(s => s.Listing)
            .FirstOrDefaultAsync(s => s.Id == saleId, ct);

        if (sale is null) return NotFound();
        if (sale.BuyerId != currentUser.UserId) return Forbid();
        if (sale.Status == "buyer_confirmed") return BadRequest("Already confirmed.");

        sale.Status = "buyer_confirmed";
        sale.ConfirmedAt = DateTime.UtcNow;
        await db.SaveChangesAsync(ct);

        return Ok(ToDto(sale));
    }

    [HttpGet("pending")]
    public async Task<ActionResult<IEnumerable<SaleRecordDto>>> Pending(CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();

        var sales = await db.SaleRecords
            .Include(s => s.Listing)
            .Where(s =>
                s.BuyerId == currentUser.UserId &&
                s.Status == "seller_reported")
            .OrderByDescending(s => s.CreatedAt)
            .ToListAsync(ct);

        return Ok(sales.Select(ToDto));
    }

    private static SaleRecordDto ToDto(SaleRecord sale) =>
        new(
            sale.Id,
            sale.ListingId,
            sale.Listing?.Title ?? "Listing",
            sale.Units,
            sale.Status,
            sale.CreatedAt,
            sale.Listing?.QuantityAvailable,
            sale.Listing?.Status ?? "active");
}
