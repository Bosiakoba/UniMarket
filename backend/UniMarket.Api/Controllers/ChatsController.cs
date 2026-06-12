using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UniMarket.Api.Data;
using UniMarket.Api.DTOs;
using UniMarket.Api.Models;
using UniMarket.Api.Services;

namespace UniMarket.Api.Controllers;

[ApiController]
[Route("api/chats")]
public class ChatsController(
    AppDbContext db,
    CurrentUserService currentUser,
    NotificationService notifications) : ControllerBase
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

    [HttpGet("{chatId}/messages")]
    public async Task<ActionResult<IEnumerable<MessageDto>>> Messages(string chatId, CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();

        var chat = await db.Chats.FindAsync([chatId], ct);
        if (chat is null) return NotFound();
        if (chat.BuyerId != currentUser.UserId && chat.SellerId != currentUser.UserId)
        {
            return Forbid();
        }

        var messages = await db.Messages
            .Where(m => m.ChatId == chatId)
            .OrderBy(m => m.SentAt)
            .ToListAsync(ct);

        var dtos = new List<MessageDto>();
        foreach (var message in messages)
        {
            dtos.Add(await ToMessageDto(message, ct));
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
            Id = Guid.NewGuid().ToString("N")[..12],
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

        var message = new Message
        {
            Id = Guid.NewGuid().ToString("N")[..12],
            ChatId = chatId,
            SenderId = currentUser.UserId!,
            Content = request.Content.Trim(),
            MessageType = "text",
        };

        db.Messages.Add(message);

        await db.SaveChangesAsync(ct);

        var recipientId = chat.BuyerId == currentUser.UserId
            ? chat.SellerId
            : chat.BuyerId;
        var sender = await db.Users.FindAsync([currentUser.UserId!], ct);

        await notifications.CreateAsync(
            recipientId,
            $"New message from {sender?.FullName ?? "UniMarket"}",
            message.Content,
            "message",
            chat.Id,
            "Reply",
            ct);

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

        var otherUserId = chat.BuyerId == currentUser.UserId
            ? chat.SellerId
            : chat.BuyerId;
        var otherParty = await db.Users.FindAsync([otherUserId], ct);

        var image = listing?.Images.OrderBy(i => i.SortOrder).FirstOrDefault()?.ImageUrl;
        var hasUnread = await db.Messages.AnyAsync(
            m => m.ChatId == chat.Id &&
                 m.SenderId != currentUser.UserId &&
                 m.MessageType == SaleConfirmationService.MessageTypeSaleConfirmation &&
                 m.ConfirmationStatus == "pending",
            ct);

        return new ChatDto(
            chat.Id,
            chat.ListingId,
            seller?.FullName ?? "Seller",
            otherParty?.FullName ?? "User",
            listing?.Title,
            image,
            listing?.Price,
            hasUnread,
            chat.CreatedAt);
    }

    private async Task<MessageDto> ToMessageDto(Message message, CancellationToken ct)
    {
        var canRespond = false;
        if (message.MessageType == SaleConfirmationService.MessageTypeSaleConfirmation &&
            message.ConfirmationStatus == "pending" &&
            message.SaleId is not null &&
            currentUser.UserId is not null)
        {
            canRespond = await db.SaleConfirmations.AnyAsync(
                c => c.SaleId == message.SaleId &&
                     c.BuyerId == currentUser.UserId &&
                     c.Status == "pending",
                ct);
        }

        return new MessageDto(
            message.Id,
            message.ChatId,
            message.SenderId,
            message.Content,
            message.MessageType,
            message.SaleId,
            message.ConfirmationStatus,
            message.SentAt,
            FormatTimeLabel(message.SentAt),
            canRespond);
    }

    private static string FormatTimeLabel(DateTime sentAt)
    {
        var delta = DateTime.UtcNow - sentAt;
        if (delta.TotalMinutes < 1) return "Just now";
        if (delta.TotalHours < 1) return $"{(int)delta.TotalMinutes}m";
        if (delta.TotalDays < 1) return $"{(int)delta.TotalHours}h";
        if (delta.TotalDays < 7) return $"{(int)delta.TotalDays}d";
        return sentAt.ToString("MMM d");
    }
}
