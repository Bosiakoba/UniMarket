using Microsoft.EntityFrameworkCore;
using UniMarket.Api.Data;
using UniMarket.Api.Models;

namespace UniMarket.Api.Services;

public class SaleConfirmationService(AppDbContext db)
{
    public const string SystemSenderId = "unimarket-system";
    public const string MessageTypeSaleConfirmation = "sale_confirmation";
    public const string MessageTypeSystemText = "system_text";

    public async Task NotifyListingEnquirersAsync(Listing listing, SaleRecord sale, CancellationToken ct)
    {
        var chats = await db.Chats
            .Where(c => c.ListingId == listing.Id)
            .ToListAsync(ct);

        if (chats.Count == 0) return;

        var prompt = listing.AvailabilityType == "ongoing"
            ? $"The seller recorded a completed job for \"{listing.Title}\". Did you hire them for this?"
            : $"The seller recorded a sale for \"{listing.Title}\". Did you buy this item?";

        foreach (var chat in chats)
        {
            db.SaleConfirmations.Add(new SaleConfirmation
            {
                Id = Guid.NewGuid().ToString("N")[..12],
                SaleId = sale.Id,
                BuyerId = chat.BuyerId,
                ChatId = chat.Id,
                Status = "pending",
                CreatedAt = DateTime.UtcNow,
            });

            db.Messages.Add(new Message
            {
                Id = Guid.NewGuid().ToString("N")[..12],
                ChatId = chat.Id,
                SenderId = SystemSenderId,
                Content = prompt,
                MessageType = MessageTypeSaleConfirmation,
                SaleId = sale.Id,
                ConfirmationStatus = "pending",
                SentAt = DateTime.UtcNow,
            });
        }

        await db.SaveChangesAsync(ct);
    }

    public async Task<(bool Success, string? Error)> RespondAsync(
        string saleId,
        string buyerUserId,
        bool confirmed,
        CancellationToken ct)
    {
        var confirmation = await db.SaleConfirmations
            .Include(c => c.Sale)
            .ThenInclude(s => s!.Listing)
            .FirstOrDefaultAsync(
                c => c.SaleId == saleId && c.BuyerId == buyerUserId,
                ct);

        if (confirmation is null)
        {
            return (false, "No confirmation request found for this sale.");
        }

        if (confirmation.Status != "pending")
        {
            return (false, "You already responded to this confirmation.");
        }

        var sale = confirmation.Sale;
        if (sale is null)
        {
            return (false, "Sale not found.");
        }

        confirmation.Status = confirmed ? "confirmed" : "denied";
        confirmation.RespondedAt = DateTime.UtcNow;

        var chatMessage = await db.Messages
            .Where(m => m.ChatId == confirmation.ChatId && m.SaleId == saleId)
            .OrderByDescending(m => m.SentAt)
            .FirstOrDefaultAsync(m => m.MessageType == MessageTypeSaleConfirmation, ct);

        if (chatMessage is not null)
        {
            chatMessage.ConfirmationStatus = confirmation.Status;
        }

        if (confirmed)
        {
            if (sale.Status == "buyer_confirmed" &&
                sale.BuyerId != buyerUserId &&
                sale.Listing?.AvailabilityType == "unique")
            {
                sale.Status = "disputed";
                db.Messages.Add(BuildSystemMessage(
                    confirmation.ChatId,
                    "Another buyer also confirmed this sale. The seller may need to clarify."));
            }
            else
            {
                sale.Status = "buyer_confirmed";
                sale.BuyerId = buyerUserId;
                sale.ConfirmedAt = DateTime.UtcNow;
                db.Messages.Add(BuildSystemMessage(
                    confirmation.ChatId,
                    "Thanks — your purchase is confirmed."));
            }
        }
        else
        {
            db.Messages.Add(BuildSystemMessage(
                confirmation.ChatId,
                "Thanks for letting us know."));

            var all = await db.SaleConfirmations
                .Where(c => c.SaleId == saleId)
                .ToListAsync(ct);

            if (!all.Any(c => c.Status == "confirmed") &&
                !all.Any(c => c.Status == "pending"))
            {
                sale.Status = "disputed";
            }
        }

        await db.SaveChangesAsync(ct);
        return (true, null);
    }

    private static Message BuildSystemMessage(string chatId, string content) =>
        new()
        {
            Id = Guid.NewGuid().ToString("N")[..12],
            ChatId = chatId,
            SenderId = SystemSenderId,
            Content = content,
            MessageType = MessageTypeSystemText,
            SentAt = DateTime.UtcNow,
        };
}
