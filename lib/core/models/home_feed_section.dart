import 'listing_item.dart';

/// Layout kinds the home API can return per feed block.
enum HomeSectionLayout {
  promo,
  categoriesHorizontal,
  categoriesGrid,
  listingsHorizontal,
  listingsGrid,
}

class HomeFeedSection {
  const HomeFeedSection({
    required this.id,
    required this.title,
    required this.layout,
    this.subtitle,
    this.listings = const [],
    this.categories = const [],
    this.actionLabel,
  });

  final String id;
  final String title;
  final String? subtitle;
  final HomeSectionLayout layout;
  final List<ListingItem> listings;
  final List<String> categories;
  final String? actionLabel;
}
