using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using UniMarket.Api.Data;
using UniMarket.Api.DTOs;
using UniMarket.Api.Models;

namespace UniMarket.Api.Services;

public class ListingMapper(AppDbContext db, R2StorageService storage)
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    private readonly Dictionary<string, (double Rating, int Count)> _sellerStatsCache = new();

    public async Task<ListingDto> ToDtoAsync(Listing listing, CancellationToken ct = default)
    {
        var owner = listing.Owner ?? await db.Users.FindAsync([listing.UserId], ct);
        var reviews = await db.ListingReviews
            .Where(r => r.ListingId == listing.Id)
            .ToListAsync(ct);

        var rating = reviews.Count == 0
            ? 0
            : reviews.Average(r => r.Score);

        var (sellerRating, sellerReviewCount) =
            await GetSellerReviewStatsAsync(listing.UserId, ct);

        var photos = listing.Images
            .OrderBy(i => i.SortOrder)
            .Select(i => storage.NormalizeMediaUrl(i.ImageUrl))
            .Where(url => !string.IsNullOrWhiteSpace(url))
            .ToList();

        if (photos.Count == 0)
        {
            photos.Add("https://placehold.co/600x600/png?text=Listing");
        }

        return new ListingDto(
            listing.Id,
            listing.Title,
            listing.Description,
            listing.Price,
            listing.OriginalPrice,
            listing.DiscountEndsAt,
            listing.DiscountDurationDays,
            listing.Category,
            listing.Condition,
            listing.MeetupLocation,
            listing.Status,
            listing.AvailabilityType,
            listing.QuantityAvailable,
            listing.UnitsSold,
            DeserializeTags(listing.TagsJson),
            DeserializeAttributes(listing.AttributesJson),
            listing.DistanceKm,
            owner?.FullName ?? "Campus seller",
            listing.UserId,
            owner?.IsVerified ?? false,
            Math.Round(rating, 1),
            reviews.Count,
            sellerRating,
            sellerReviewCount,
            photos,
            listing.CreatedAt);
    }

    private async Task<(double Rating, int Count)> GetSellerReviewStatsAsync(
        string userId,
        CancellationToken ct)
    {
        if (_sellerStatsCache.TryGetValue(userId, out var cached))
        {
            return cached;
        }

        var sellerReviews = await (
            from review in db.ListingReviews
            join sellerListing in db.Listings on review.ListingId equals sellerListing.Id
            where sellerListing.UserId == userId
            select review).ToListAsync(ct);

        var stats = sellerReviews.Count == 0
            ? (0d, 0)
            : (Math.Round(sellerReviews.Average(r => r.Score), 1), sellerReviews.Count);

        _sellerStatsCache[userId] = stats;
        return stats;
    }

    public static IReadOnlyList<string> DeserializeTags(string json)
    {
        try
        {
            return JsonSerializer.Deserialize<List<string>>(json, JsonOptions) ?? [];
        }
        catch
        {
            return [];
        }
    }

    public static IReadOnlyDictionary<string, string> DeserializeAttributes(string json)
    {
        try
        {
            return JsonSerializer.Deserialize<Dictionary<string, string>>(json, JsonOptions)
                   ?? new Dictionary<string, string>();
        }
        catch
        {
            return new Dictionary<string, string>();
        }
    }

    public static string SerializeTags(IEnumerable<string> tags) =>
        JsonSerializer.Serialize(tags, JsonOptions);

    public static string SerializeAttributes(IReadOnlyDictionary<string, string> attributes) =>
        JsonSerializer.Serialize(attributes, JsonOptions);
}
