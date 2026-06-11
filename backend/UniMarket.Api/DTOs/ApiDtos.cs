namespace UniMarket.Api.DTOs;

public record SessionRequest(string? FirebaseIdToken, string? DevUserId);

public record UserProfileDto(
    string Id,
    string? FirebaseUid,
    string FullName,
    string Email,
    string Role,
    bool IsSeller,
    bool IsVerified,
    string? AvatarUrl,
    string University,
    string Campus,
    string? Phone,
    DateTime CreatedAt);

public record UpdateProfileRequest(
    string? FullName,
    string? University,
    string? Campus,
    string? Phone,
    string? AvatarUrl);

public record ListingDto(
    string Id,
    string Title,
    string Description,
    decimal Price,
    decimal? OriginalPrice,
    DateTime? DiscountEndsAt,
    int? DiscountDurationDays,
    string Category,
    string? Condition,
    string? MeetupLocation,
    string Status,
    IReadOnlyList<string> Tags,
    IReadOnlyDictionary<string, string> Attributes,
    double DistanceKm,
    string SellerName,
    bool IsVerified,
    double Rating,
    int ReviewCount,
    IReadOnlyList<string> PhotoUrls,
    DateTime CreatedAt);

public record CreateListingRequest(
    string Title,
    string Description,
    decimal Price,
    string Category,
    string? Condition,
    string? MeetupLocation,
    IReadOnlyList<string> Tags,
    IReadOnlyDictionary<string, string> Attributes,
    IReadOnlyList<string> PhotoUrls,
    decimal? OriginalPrice,
    DateTime? DiscountEndsAt,
    int? DiscountDurationDays);

public record SellerApplicationRequest(string StoreName, string? IdDocumentUrl);

public record ChatDto(
    string Id,
    string ListingId,
    string SellerName,
    string? ListingTitle,
    string? ListingImageUrl,
    decimal? ListingPrice,
    bool Unread,
    DateTime CreatedAt);

public record SendMessageRequest(string Content);

public record ListingReviewDto(
    string Id,
    string AuthorName,
    double Rating,
    string Body,
    string DateLabel);

public record CreateReviewRequest(int Score, string Comment);

public record ReportListingRequest(string Reason, string? Comment);

public record FeedSectionDto(string Key, string Title, IReadOnlyList<ListingDto> Items);
