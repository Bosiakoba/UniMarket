import 'listing_availability.dart';
import 'listing_item.dart';

enum ListingStatus { active, sold, soldOut, paused }

class SellerListingRecord {
  const SellerListingRecord({
    required this.listing,
    required this.views,
    required this.messages,
    required this.postedLabel,
    this.description = '',
    this.condition = 'Like new',
    this.meetupLocation = 'Main Campus',
    this.photoAssets = const [],
  });

  final ListingItem listing;
  final int views;
  final int messages;
  final String postedLabel;
  final String description;
  final String condition;
  final String meetupLocation;
  final List<String> photoAssets;

  bool get isActive => listing.isBrowseable;

  ListingStatus get status => switch (listing.lifecycleStatus) {
        ListingLifecycleStatus.sold => ListingStatus.sold,
        ListingLifecycleStatus.soldOut => ListingStatus.soldOut,
        ListingLifecycleStatus.paused => ListingStatus.paused,
        ListingLifecycleStatus.active => ListingStatus.active,
      };

  String get statusLabel {
    if (listing.isBrowseable) return listing.availabilityLabel;
    return switch (listing.lifecycleStatus) {
      ListingLifecycleStatus.sold => 'Sold',
      ListingLifecycleStatus.soldOut => 'Sold out',
      ListingLifecycleStatus.paused => 'Paused',
      ListingLifecycleStatus.active => 'Active',
    };
  }

  List<String> get allPhotoAssets => photoAssets.isNotEmpty
      ? photoAssets
      : (listing.imageAsset.isNotEmpty ? [listing.imageAsset] : const []);

  SellerListingRecord copyWith({
    String? postedLabel,
    String? description,
    String? condition,
    String? meetupLocation,
    List<String>? photoAssets,
  }) {
    return SellerListingRecord(
      listing: listing,
      views: views,
      messages: messages,
      postedLabel: postedLabel ?? this.postedLabel,
      description: description ?? this.description,
      condition: condition ?? this.condition,
      meetupLocation: meetupLocation ?? this.meetupLocation,
      photoAssets: photoAssets ?? this.photoAssets,
    );
  }

  SellerListingRecord copyWithListing(ListingItem updatedListing) {
    return SellerListingRecord(
      listing: updatedListing,
      views: views,
      messages: messages,
      postedLabel: postedLabel,
      description: description,
      condition: condition,
      meetupLocation: meetupLocation,
      photoAssets: photoAssets,
    );
  }
}
