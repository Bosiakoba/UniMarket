using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UniMarket.Api.Data;
using UniMarket.Api.DTOs;
using UniMarket.Api.Models;
using UniMarket.Api.Services;

namespace UniMarket.Api.Controllers;

[ApiController]
[Route("api/chats")]
public class ChatsController(AppDbContext db, CurrentUserService currentUser) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<ChatDto>>> List(CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();

        var chats = await db.Chats
            .Where(c => c.BuyerId == currentUser.UserId || c.SellerId == currentUser.UserId)
            .OrderByDescending(c => c.CreatedAt)
            .ToListAsync(ct);

        var dtos = new List<ChatDto>();
        foreach (var chat in chats)
        {
            dtos.Add(await ToDto(chat, ct));
        }

        return Ok(dtos);
    }

    [HttpPost]
    public async Task<ActionResult<ChatDto>> Open(
        [FromQuery] string listingId,
        CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();

        var listing = await db.Listings
            .Include(l => l.Owner)
            .Include(l => l.Images)
            .FirstOrDefaultAsync(l => l.Id == listingId, ct);

        if (listing is null) return NotFound();
        if (listing.UserId == currentUser.UserId)
        {
            return BadRequest(new { message = "Cannot chat with yourself." });
        }

        var existing = await db.Chats.FirstOrDefaultAsync(
            c => c.ListingId == listingId && c.BuyerId == currentUser.UserId, ct);

        if (existing is not null)
        {
            return Ok(await ToDto(existing, ct));
        }

        var chat = new Chat
        {
            Id = Guid.NewGuid().ToString("N"),
            ListingId = listingId,
            BuyerId = currentUser.UserId!,
            SellerId = listing.UserId,
        };

        db.Chats.Add(chat);
        await db.SaveChangesAsync(ct);
        return Ok(await ToDto(chat, ct));
    }

    [HttpPost("{chatId}/messages")]
    public async Task<IActionResult> SendMessage(
        string chatId,
        [FromBody] SendMessageRequest request,
        CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();

        var chat = await db.Chats.FindAsync([chatId], ct);
        if (chat is null) return NotFound();
        if (chat.BuyerId != currentUser.UserId && chat.SellerId != currentUser.UserId)
        {
            return Forbid();
        }

        if (string.IsNullOrWhiteSpace(request.Content))
        {
            return BadRequest();
        }

        db.Messages.Add(new Message
        {
            Id = Guid.NewGuid().ToString("N"),
            ChatId = chatId,
            SenderId = currentUser.UserId!,
            Content = request.Content.Trim(),
        });

        await db.SaveChangesAsync(ct);
        return Ok();
    }

    private async Task<ChatDto> ToDto(Chat chat, CancellationToken ct)
    {
        var listing = await db.Listings
            .Include(l => l.Owner)
            .Include(l => l.Images)
            .FirstOrDefaultAsync(l => l.Id == chat.ListingId, ct);

        var seller = listing?.Owner
            ?? await db.Users.FindAsync([chat.SellerId], ct);

        var image = listing?.Images.OrderBy(i => i.SortOrder).FirstOrDefault()?.ImageUrl;

        return new ChatDto(
            chat.Id,
            chat.ListingId,
            seller?.FullName ?? "Seller",
            listing?.Title,
            image,
            listing?.Price,
            false,
            chat.CreatedAt);
    }
}
