using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UniMarket.Api.Data;
using UniMarket.Api.DTOs;
using UniMarket.Api.Models;
using UniMarket.Api.Services;

namespace UniMarket.Api.Controllers;

[ApiController]
[Route("api/sales")]
public class SalesController(
    AppDbContext db,
    CurrentUserService currentUser,
    SaleConfirmationService saleConfirmation) : ControllerBase
{
    [HttpPost("{saleId}/respond")]
    public async Task<ActionResult<SaleRecordDto>> Respond(
        string saleId,
        [FromBody] SaleRespondRequest request,
        CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();

        var (success, error) = await saleConfirmation.RespondAsync(
            saleId,
            currentUser.UserId!,
            request.Confirmed,
            ct);

        if (!success)
        {
            return BadRequest(new { message = error });
        }

        var sale = await db.SaleRecords
            .Include(s => s.Listing)
            .FirstAsync(s => s.Id == saleId, ct);

        return Ok(ToDto(sale));
    }

    [HttpPost("{saleId}/confirm")]
    public Task<ActionResult<SaleRecordDto>> Confirm(string saleId, CancellationToken ct) =>
        Respond(saleId, new SaleRespondRequest(true), ct);

    [HttpGet("pending")]
    public async Task<ActionResult<IEnumerable<SaleRecordDto>>> Pending(CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();

        var buyerId = currentUser.UserId!;
        var pendingSaleIds = await db.SaleConfirmations
            .Where(c => c.BuyerId == buyerId && c.Status == "pending")
            .Select(c => c.SaleId)
            .Distinct()
            .ToListAsync(ct);

        var sales = await db.SaleRecords
            .Include(s => s.Listing)
            .Where(s => pendingSaleIds.Contains(s.Id))
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
