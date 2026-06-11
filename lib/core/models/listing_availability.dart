import 'category_field.dart';

/// How a listing handles sales — aligned with Meta/Facebook catalog patterns:
/// unique items close on sale; stock decrements until sold out; services stay live.
enum ListingAvailabilityType {
  /// One-of-a-kind (used textbook, single fridge). Sale closes the listing.
  unique,

  /// Multiple identical units (10 notebooks, 6 pie packs). Sale decrements stock.
  stock,

  /// Services and gigs — each sale is recorded; listing stays active.
  ongoing,
}

enum ListingLifecycleStatus {
  active,
  sold,
  soldOut,
  paused,
}

abstract final class ListingAvailabilityRules {
  static ListingAvailabilityType defaultForKind(ListingKind kind) {
    return switch (kind) {
      ListingKind.service || ListingKind.job => ListingAvailabilityType.ongoing,
      _ => ListingAvailabilityType.unique,
    };
  }

  static bool supportsStock(ListingKind kind) {
    return switch (kind) {
      ListingKind.service || ListingKind.job => false,
      _ => true,
    };
  }

  static String recordSaleLabel(ListingAvailabilityType type) {
    return switch (type) {
      ListingAvailabilityType.ongoing => 'Record completed job',
      ListingAvailabilityType.stock => 'Record sale',
      ListingAvailabilityType.unique => 'Record sale',
    };
  }

  static String recordSaleSuccessMessage({
    required ListingAvailabilityType type,
    required int units,
    required int? quantityRemaining,
    required bool listingClosed,
  }) {
    return switch (type) {
      ListingAvailabilityType.ongoing =>
        'Recorded $units completed ${units == 1 ? 'job' : 'jobs'}. Listing stays active.',
      ListingAvailabilityType.stock when listingClosed =>
        'Recorded $units sale${units == 1 ? '' : 's'}. Listing is now sold out.',
      ListingAvailabilityType.stock =>
        'Recorded $units sale${units == 1 ? '' : 's'}. $quantityRemaining left in stock.',
      ListingAvailabilityType.unique =>
        'Sale recorded. Listing removed from campus feed.',
    };
  }

  static bool isBrowseable({
    required ListingLifecycleStatus lifecycleStatus,
    required ListingAvailabilityType availabilityType,
    required int? quantityAvailable,
  }) {
    if (lifecycleStatus != ListingLifecycleStatus.active) return false;
    if (availabilityType == ListingAvailabilityType.stock) {
      return (quantityAvailable ?? 0) > 0;
    }
    return true;
  }

  static ListingLifecycleStatus lifecycleFromApi(String? value) {
    return switch (value) {
      'sold' => ListingLifecycleStatus.sold,
      'sold_out' => ListingLifecycleStatus.soldOut,
      'paused' => ListingLifecycleStatus.paused,
      _ => ListingLifecycleStatus.active,
    };
  }

  static String lifecycleToApi(ListingLifecycleStatus status) {
    return switch (status) {
      ListingLifecycleStatus.sold => 'sold',
      ListingLifecycleStatus.soldOut => 'sold_out',
      ListingLifecycleStatus.paused => 'paused',
      ListingLifecycleStatus.active => 'active',
    };
  }

  static ListingAvailabilityType typeFromApi(String? value) {
    return switch (value) {
      'stock' => ListingAvailabilityType.stock,
      'ongoing' => ListingAvailabilityType.ongoing,
      _ => ListingAvailabilityType.unique,
    };
  }

  static String typeToApi(ListingAvailabilityType type) {
    return switch (type) {
      ListingAvailabilityType.stock => 'stock',
      ListingAvailabilityType.ongoing => 'ongoing',
      ListingAvailabilityType.unique => 'unique',
    };
  }

  static String availabilityLabel({
    required ListingAvailabilityType type,
    required ListingLifecycleStatus lifecycleStatus,
    required int? quantityAvailable,
    required int unitsSold,
  }) {
    if (lifecycleStatus == ListingLifecycleStatus.sold) return 'Sold';
    if (lifecycleStatus == ListingLifecycleStatus.soldOut) return 'Sold out';
    if (lifecycleStatus == ListingLifecycleStatus.paused) return 'Paused';

    return switch (type) {
      ListingAvailabilityType.stock =>
        '${quantityAvailable ?? 0} left · $unitsSold sold',
      ListingAvailabilityType.ongoing =>
        unitsSold == 0 ? 'Service · open' : '$unitsSold completed',
      ListingAvailabilityType.unique => 'One item',
    };
  }
}
