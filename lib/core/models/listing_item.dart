import 'listing_availability.dart';

class ListingItem {
  const ListingItem({
    required this.id,
    required this.title,
    required this.price,
    required this.imageAsset,
    required this.sellerName,
    required this.isVerified,
    required this.distanceKm,
    required this.category,
    this.tags = const [],
    this.attributes = const {},
    this.rating = 4.8,
    this.reviewCount = 24,
    this.sellerRating = 4.8,
    this.sellerReviewCount = 38,
    this.originalPrice,
    this.discountEndsAt,
    this.discountDurationDays,
    this.photoUrls = const [],
    this.availabilityType = ListingAvailabilityType.unique,
    this.quantityAvailable,
    this.unitsSold = 0,
    this.lifecycleStatus = ListingLifecycleStatus.active,
  });

  final String id;
  final String title;
  final double price;
  final String imageAsset;
  final List<String> photoUrls;
  final String sellerName;
  final bool isVerified;
  final double distanceKm;
  final String category;
  final List<String> tags;
  final Map<String, String> attributes;
  final double rating;
  final int reviewCount;
  final double sellerRating;
  final int sellerReviewCount;
  final double? originalPrice;
  final DateTime? discountEndsAt;
  final int? discountDurationDays;
  final ListingAvailabilityType availabilityType;
  final int? quantityAvailable;
  final int unitsSold;
  final ListingLifecycleStatus lifecycleStatus;

  bool get hasActiveDiscount {
    if (originalPrice == null || discountEndsAt == null) return false;
    return originalPrice! > price && discountEndsAt!.isAfter(DateTime.now());
  }

  int? get discountPercent {
    if (!hasActiveDiscount || originalPrice == null || originalPrice! <= 0) {
      return null;
    }
    return (((originalPrice! - price) / originalPrice!) * 100).round();
  }

  int get discountDaysRemaining {
    if (discountEndsAt == null) return 0;
    final remaining = discountEndsAt!.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining + 1;
  }

  String get formattedPrice => 'GHS ${price.toStringAsFixed(0)}';

  String? get formattedOriginalPrice {
    if (originalPrice == null) return null;
    return 'GHS ${originalPrice!.toStringAsFixed(0)}';
  }

  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km';

  bool get isBrowseable => ListingAvailabilityRules.isBrowseable(
        lifecycleStatus: lifecycleStatus,
        availabilityType: availabilityType,
        quantityAvailable: quantityAvailable,
      );

  String get availabilityLabel => ListingAvailabilityRules.availabilityLabel(
        type: availabilityType,
        lifecycleStatus: lifecycleStatus,
        quantityAvailable: quantityAvailable,
        unitsSold: unitsSold,
      );

  List<String> get displayPhotos =>
      photoUrls.isNotEmpty ? photoUrls : [imageAsset];

  String get primaryPhotoSource {
    for (final photo in displayPhotos) {
      final trimmed = photo.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return imageAsset;
  }

  bool get usesNetworkImages => displayPhotos.any((photo) {
        final trimmed = photo.trim().toLowerCase();
        return trimmed.startsWith('http://') ||
            trimmed.startsWith('https://') ||
            trimmed.contains('://');
      });
  String get sellerInitial =>
      sellerName.isNotEmpty ? sellerName[0].toUpperCase() : '?';
  String get ratingLabel =>
      '${rating.toStringAsFixed(1)} ($reviewCount reviews)';
  String get sellerRatingLabel =>
      '${sellerRating.toStringAsFixed(1)} ($sellerReviewCount reviews)';

  /// Feed placeholders may suffix ids with `-dup`; resolve to the real listing.
  String get canonicalId =>
      id.endsWith('-dup') ? id.substring(0, id.length - 4) : id;

  ListingItem resolveAgainst(Iterable<ListingItem> catalog) {
    final targetId = canonicalId;
    for (final item in catalog) {
      if (item.id == targetId) return item;
    }
    if (id == targetId) return this;
    return copyWith(id: targetId);
  }

  ListingItem copyWith({
    String? id,
    String? title,
    double? price,
    String? imageAsset,
    List<String>? photoUrls,
    String? sellerName,
    bool? isVerified,
    double? distanceKm,
    String? category,
    List<String>? tags,
    Map<String, String>? attributes,
    double? rating,
    int? reviewCount,
    double? sellerRating,
    int? sellerReviewCount,
    double? originalPrice,
    DateTime? discountEndsAt,
    int? discountDurationDays,
    ListingAvailabilityType? availabilityType,
    int? quantityAvailable,
    int? unitsSold,
    ListingLifecycleStatus? lifecycleStatus,
    bool clearOriginalPrice = false,
    bool clearDiscountEndsAt = false,
    bool clearDiscountDurationDays = false,
    bool clearQuantityAvailable = false,
  }) {
    return ListingItem(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      imageAsset: imageAsset ?? this.imageAsset,
      photoUrls: photoUrls ?? this.photoUrls,
      sellerName: sellerName ?? this.sellerName,
      isVerified: isVerified ?? this.isVerified,
      distanceKm: distanceKm ?? this.distanceKm,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      attributes: attributes ?? this.attributes,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      sellerRating: sellerRating ?? this.sellerRating,
      sellerReviewCount: sellerReviewCount ?? this.sellerReviewCount,
      originalPrice:
          clearOriginalPrice ? null : (originalPrice ?? this.originalPrice),
      discountEndsAt:
          clearDiscountEndsAt ? null : (discountEndsAt ?? this.discountEndsAt),
      discountDurationDays: clearDiscountDurationDays
          ? null
          : (discountDurationDays ?? this.discountDurationDays),
      availabilityType: availabilityType ?? this.availabilityType,
      quantityAvailable: clearQuantityAvailable
          ? null
          : (quantityAvailable ?? this.quantityAvailable),
      unitsSold: unitsSold ?? this.unitsSold,
      lifecycleStatus: lifecycleStatus ?? this.lifecycleStatus,
    );
  }
}
