using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using UniMarket.Api.Data;
using UniMarket.Api.DTOs;
using UniMarket.Api.Models;

namespace UniMarket.Api.Services;

public class ListingMapper(AppDbContext db)
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    public async Task<ListingDto> ToDtoAsync(Listing listing, CancellationToken ct = default)
    {
        var owner = listing.Owner ?? await db.Users.FindAsync([listing.UserId], ct);
        var reviews = await db.ListingReviews
            .Where(r => r.ListingId == listing.Id)
            .ToListAsync(ct);

        var rating = reviews.Count == 0
            ? 4.8
            : reviews.Average(r => r.Score);

        var photos = listing.Images
            .OrderBy(i => i.SortOrder)
            .Select(i => i.ImageUrl)
            .ToList();

        if (photos.Count == 0)
        {
            photos.Add("https://placehold.co/600x600?text=Listing");
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
            DeserializeTags(listing.TagsJson),
            DeserializeAttributes(listing.AttributesJson),
            listing.DistanceKm,
            owner?.FullName ?? "Campus seller",
            owner?.IsVerified ?? false,
            Math.Round(rating, 1),
            reviews.Count,
            photos,
            listing.CreatedAt);
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
