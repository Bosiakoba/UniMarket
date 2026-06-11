namespace UniMarket.Api.Models;

public class User
{
    public string Id { get; set; } = string.Empty;
    public string? FirebaseUid { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Role { get; set; } = "Student";
    public bool IsSeller { get; set; }
    public bool IsVerified { get; set; }
    public string? AvatarUrl { get; set; }
    public string University { get; set; } = "State University";
    public string Campus { get; set; } = "Main Campus";
    public string? Phone { get; set; }
    public bool ProfileComplete { get; set; }
    public string InterestCategoriesJson { get; set; } = "[]";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public ICollection<Listing> Listings { get; set; } = new List<Listing>();
}

public class Listing
{
    public string Id { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;
    public User? Owner { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public decimal? OriginalPrice { get; set; }
    public DateTime? DiscountEndsAt { get; set; }
    public int? DiscountDurationDays { get; set; }
    public string Category { get; set; } = string.Empty;
    public string? Condition { get; set; }
    public string? MeetupLocation { get; set; }
    public string Status { get; set; } = "active";
    public string AvailabilityType { get; set; } = "unique";
    public int? QuantityAvailable { get; set; }
    public int UnitsSold { get; set; }
    public string TagsJson { get; set; } = "[]";
    public string AttributesJson { get; set; } = "{}";
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public double DistanceKm { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public ICollection<ListingImage> Images { get; set; } = new List<ListingImage>();
}

public class ListingImage
{
    public string Id { get; set; } = string.Empty;
    public string ListingId { get; set; } = string.Empty;
    public Listing? Listing { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public int SortOrder { get; set; }
}

public class Chat
{
    public string Id { get; set; } = string.Empty;
    public string ListingId { get; set; } = string.Empty;
    public string BuyerId { get; set; } = string.Empty;
    public string SellerId { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public ICollection<Message> Messages { get; set; } = new List<Message>();
}

public class Message
{
    public string Id { get; set; } = string.Empty;
    public string ChatId { get; set; } = string.Empty;
    public string SenderId { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public string MessageType { get; set; } = "text";
    public string? SaleId { get; set; }
    public string? ConfirmationStatus { get; set; }
    public DateTime SentAt { get; set; } = DateTime.UtcNow;
}

public class VerificationRequest
{
    public string Id { get; set; } = string.Empty;
    public string UserId { get; set; } = string.Empty;
    public User? User { get; set; }
    public string RequestType { get; set; } = "seller_application";
    public string Status { get; set; } = "Pending";
    public string? StoreName { get; set; }
    public string? IdDocumentUrl { get; set; }
    public string? AiReviewSummary { get; set; }
    public string? AiRecommendation { get; set; }
    public string? AdminNotes { get; set; }
    public DateTime SubmittedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ProcessedAt { get; set; }
}

public class ListingReview
{
    public string Id { get; set; } = string.Empty;
    public string ListingId { get; set; } = string.Empty;
    public string AuthorUserId { get; set; } = string.Empty;
    public string AuthorName { get; set; } = string.Empty;
    public int Score { get; set; }
    public string Comment { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class ListingReport
{
    public string Id { get; set; } = string.Empty;
    public string ListingId { get; set; } = string.Empty;
    public string ReporterUserId { get; set; } = string.Empty;
    public string Reason { get; set; } = string.Empty;
    public string? Comment { get; set; }
    public string Status { get; set; } = "Pending";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

public class WishlistItem
{
    public string UserId { get; set; } = string.Empty;
    public string ListingId { get; set; } = string.Empty;
    public DateTime SavedAt { get; set; } = DateTime.UtcNow;
}

public class SaleRecord
{
    public string Id { get; set; } = string.Empty;
    public string ListingId { get; set; } = string.Empty;
    public Listing? Listing { get; set; }
    public string SellerId { get; set; } = string.Empty;
    public string? BuyerId { get; set; }
    public int Units { get; set; } = 1;
    public string Status { get; set; } = "seller_reported";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ConfirmedAt { get; set; }
    public ICollection<SaleConfirmation> Confirmations { get; set; } = new List<SaleConfirmation>();
}

public class SaleConfirmation
{
    public string Id { get; set; } = string.Empty;
    public string SaleId { get; set; } = string.Empty;
    public SaleRecord? Sale { get; set; }
    public string BuyerId { get; set; } = string.Empty;
    public string ChatId { get; set; } = string.Empty;
    public string Status { get; set; } = "pending";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? RespondedAt { get; set; }
}
