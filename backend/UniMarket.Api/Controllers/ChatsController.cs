using System.Text.Json;
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
    NotificationService notifications,
    R2StorageService storage) : ControllerBase
{
    private static readonly JsonSerializerOptions InquiryJsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        PropertyNameCaseInsensitive = true,
    };

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

    [HttpPost("{chatId}/read")]
    public async Task<IActionResult> MarkRead(string chatId, CancellationToken ct)
    {
        if (!currentUser.IsAuthenticated) return Unauthorized();

        var chat = await db.Chats.FindAsync([chatId], ct);
        if (chat is null) return NotFound();
        if (chat.BuyerId != currentUser.UserId && chat.SellerId != currentUser.UserId)
        {
            return Forbid();
        }

        var now = DateTime.UtcNow;
        if (chat.BuyerId == currentUser.UserId)
        {
            chat.BuyerLastReadAt = now;
        }
        else
        {
            chat.SellerLastReadAt = now;
        }

        await db.SaveChangesAsync(ct);
        return Ok();
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
        await EnsureListingInquiryMessageAsync(chat.Id, listingId, ct);
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

        var hasContent = !string.IsNullOrWhiteSpace(request.Content);
        var hasListing = !string.IsNullOrWhiteSpace(request.ListingId);
        if (!hasContent && !hasListing)
        {
            return BadRequest();
        }

        if (hasListing)
        {
            await EnsureListingInquiryMessageAsync(chatId, request.ListingId!.Trim(), ct);
        }

        var content = hasContent
            ? request.Content.Trim()
            : "Shared a listing inquiry";

        var message = new Message
        {
            Id = Guid.NewGuid().ToString("N")[..12],
            ChatId = chatId,
            SenderId = currentUser.UserId!,
            Content = content,
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

        var image = storage.NormalizeMediaUrl(
            listing?.Images.OrderBy(i => i.SortOrder).FirstOrDefault()?.ImageUrl);
        var isBuyer = chat.BuyerId == currentUser.UserId;
        var hasUnread = await ComputeUnreadAsync(chat, ct);

        return new ChatDto(
            chat.Id,
            chat.ListingId,
            seller?.FullName ?? "Seller",
            otherParty?.FullName ?? "User",
            listing?.Title,
            image,
            listing?.Price,
            isBuyer,
            hasUnread,
            chat.CreatedAt);
    }

    private async Task<bool> ComputeUnreadAsync(Chat chat, CancellationToken ct)
    {
        var lastRead = chat.BuyerId == currentUser.UserId
            ? chat.BuyerLastReadAt
            : chat.SellerLastReadAt;

        var unreadCandidates = await db.Messages
            .Where(m => m.ChatId == chat.Id &&
                        m.SenderId != currentUser.UserId &&
                        (!lastRead.HasValue || m.SentAt > lastRead.Value))
            .OrderByDescending(m => m.SentAt)
            .ToListAsync(ct);

        foreach (var message in unreadCandidates)
        {
            if (message.MessageType == SaleConfirmationService.MessageTypeSaleConfirmation)
            {
                if (chat.BuyerId != currentUser.UserId ||
                    message.ConfirmationStatus != "pending")
                {
                    continue;
                }

                if (message.SaleId is null)
                {
                    continue;
                }

                var pendingForBuyer = await db.SaleConfirmations.AnyAsync(
                    c => c.SaleId == message.SaleId &&
                         c.BuyerId == currentUser.UserId &&
                         c.Status == "pending",
                    ct);

                if (pendingForBuyer)
                {
                    return true;
                }

                continue;
            }

            if (message.MessageType == SaleConfirmationService.MessageTypeSystemText)
            {
                continue;
            }

            return true;
        }

        return false;
    }

    private async Task EnsureListingInquiryMessageAsync(
        string chatId,
        string listingId,
        CancellationToken ct)
    {
        var alreadyShared = await db.Messages.AnyAsync(
            m => m.ChatId == chatId &&
                 m.MessageType == "listing_inquiry" &&
                 m.Content.Contains(listingId, StringComparison.Ordinal),
            ct);

        if (alreadyShared)
        {
            return;
        }

        var listing = await db.Listings
            .Include(l => l.Images)
            .Include(l => l.Owner)
            .FirstOrDefaultAsync(l => l.Id == listingId, ct);

        if (listing is null)
        {
            return;
        }

        var snapshot = new ListingInquirySnapshot(
            listing.Id,
            listing.Title,
            listing.Price,
            storage.NormalizeMediaUrl(
                listing.Images.OrderBy(i => i.SortOrder).FirstOrDefault()?.ImageUrl),
            listing.UserId);

        var inquiry = new Message
        {
            Id = Guid.NewGuid().ToString("N")[..12],
            ChatId = chatId,
            SenderId = currentUser.UserId ?? listing.UserId,
            Content = JsonSerializer.Serialize(snapshot, InquiryJsonOptions),
            MessageType = "listing_inquiry",
        };

        db.Messages.Add(inquiry);
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

        string? listingId = null;
        string? listingTitle = null;
        decimal? listingPrice = null;
        string? listingImageUrl = null;
        var displayContent = message.Content;

        if (message.MessageType == "listing_inquiry")
        {
            try
            {
                var snapshot = JsonSerializer.Deserialize<ListingInquirySnapshot>(
                    message.Content,
                    InquiryJsonOptions);
                if (snapshot is not null)
                {
                    listingId = snapshot.ListingId;
                    listingTitle = snapshot.Title;
                    listingPrice = snapshot.Price;
                    listingImageUrl = storage.NormalizeMediaUrl(snapshot.ImageUrl);
                    displayContent = $"Inquiry about: {snapshot.Title}";
                }
            }
            catch (JsonException)
            {
                displayContent = "Shared a listing inquiry";
            }
        }

        return new MessageDto(
            message.Id,
            message.ChatId,
            message.SenderId,
            displayContent,
            message.MessageType,
            message.SaleId,
            message.ConfirmationStatus,
            message.SentAt,
            FormatTimeLabel(message.SentAt),
            canRespond,
            listingId,
            listingTitle,
            listingPrice,
            listingImageUrl);
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
