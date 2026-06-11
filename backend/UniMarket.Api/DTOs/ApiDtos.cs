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
    bool ProfileComplete,
    IReadOnlyList<string> InterestCategories,
    DateTime CreatedAt);

public record UpdateProfileRequest(
    string? FullName,
    string? University,
    string? Campus,
    string? Phone,
    string? AvatarUrl,
    bool? MarkProfileComplete,
    IReadOnlyList<string>? InterestCategories);

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
    string AvailabilityType,
    int? QuantityAvailable,
    int UnitsSold,
    IReadOnlyList<string> Tags,
    IReadOnlyDictionary<string, string> Attributes,
    double DistanceKm,
    string SellerName,
    bool IsVerified,
    double Rating,
    int ReviewCount,
    IReadOnlyList<string> PhotoUrls,
    DateTime CreatedAt);

public record UploadPhotoResponse(string Url);

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
    int? DiscountDurationDays,
    string AvailabilityType = "unique",
    int? QuantityAvailable = null);

public record RecordSaleRequest(int Units = 1, string? BuyerUserId = null);

public record RestockRequest(int Quantity);

public record SaleRecordDto(
    string Id,
    string ListingId,
    string ListingTitle,
    int Units,
    string Status,
    DateTime CreatedAt,
    int? QuantityRemaining,
    string ListingStatus);

public record SaleRespondRequest(bool Confirmed);

public record MessageDto(
    string Id,
    string ChatId,
    string SenderId,
    string Content,
    string MessageType,
    string? SaleId,
    string? ConfirmationStatus,
    DateTime SentAt,
    string TimeLabel,
    bool CanRespond);

public record SellerApplicationRequest(string StoreName, string? IdDocumentUrl);

public record ChatDto(
    string Id,
    string ListingId,
    string SellerName,
    string OtherPartyName,
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
