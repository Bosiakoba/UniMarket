import 'listing_item.dart';

enum ListingStatus { active, sold }

class SellerListingRecord {
  const SellerListingRecord({
    required this.listing,
    required this.views,
    required this.messages,
    required this.status,
    required this.postedLabel,
    this.description = '',
    this.condition = 'Like new',
    this.meetupLocation = 'Main Campus',
    this.photoAssets = const [],
  });

  final ListingItem listing;
  final int views;
  final int messages;
  final ListingStatus status;
  final String postedLabel;
  final String description;
  final String condition;
  final String meetupLocation;
  final List<String> photoAssets;

  bool get isActive => status == ListingStatus.active;

  String get statusLabel => isActive ? 'Active' : 'Sold';

  List<String> get allPhotoAssets => photoAssets.isNotEmpty
      ? photoAssets
      : (listing.imageAsset.isNotEmpty ? [listing.imageAsset] : const []);

  SellerListingRecord copyWith({
    ListingStatus? status,
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
      status: status ?? this.status,
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
      status: status,
      postedLabel: postedLabel,
      description: description,
      condition: condition,
      meetupLocation: meetupLocation,
      photoAssets: photoAssets,
    );
  }
}
