using Microsoft.EntityFrameworkCore;
using UniMarket.Api.Data;
using UniMarket.Api.Models;

namespace UniMarket.Api.Services;

public static class ListingDeletionService
{
    public static async Task DeleteAsync(
        AppDbContext db,
        Listing listing,
        R2StorageService? storage,
        CancellationToken ct)
    {
        var listingId = listing.Id;

        var saleIds = await db.SaleRecords
            .Where(s => s.ListingId == listingId)
            .Select(s => s.Id)
            .ToListAsync(ct);

        if (saleIds.Count > 0)
        {
            var confirmations = await db.SaleConfirmations
                .Where(c => saleIds.Contains(c.SaleId))
                .ToListAsync(ct);
            db.SaleConfirmations.RemoveRange(confirmations);
        }

        var chatIds = await db.Chats
            .Where(c => c.ListingId == listingId)
            .Select(c => c.Id)
            .ToListAsync(ct);

        if (chatIds.Count > 0)
        {
            var messages = await db.Messages
                .Where(m => chatIds.Contains(m.ChatId))
                .ToListAsync(ct);
            db.Messages.RemoveRange(messages);
        }

        db.SaleRecords.RemoveRange(
            await db.SaleRecords.Where(s => s.ListingId == listingId).ToListAsync(ct));
        db.Chats.RemoveRange(
            await db.Chats.Where(c => c.ListingId == listingId).ToListAsync(ct));
        db.ListingReviews.RemoveRange(
            await db.ListingReviews.Where(r => r.ListingId == listingId).ToListAsync(ct));
        db.ListingReports.RemoveRange(
            await db.ListingReports.Where(r => r.ListingId == listingId).ToListAsync(ct));
        db.WishlistItems.RemoveRange(
            await db.WishlistItems.Where(w => w.ListingId == listingId).ToListAsync(ct));

        var images = await db.ListingImages
            .Where(i => i.ListingId == listingId)
            .ToListAsync(ct);

        if (storage is not null)
        {
            await storage.DeleteByUrlsAsync(images.Select(i => i.ImageUrl), ct);
        }

        db.ListingImages.RemoveRange(images);

        db.Listings.Remove(listing);
    }
}
