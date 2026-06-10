import '../../constants/market_categories.dart';
import '../../models/home_feed_section.dart';
import '../../models/listing_item.dart';

/// Builds the home feed from listing data.
/// Replace [buildFeed] with an API call when the backend is ready.
abstract final class HomeFeedService {
  static List<HomeFeedSection> buildFeed(List<ListingItem> listings) {
    final categories = MarketCategories.listingCategories;
    final pool = listings;

    return [
      const HomeFeedSection(
        id: 'promo',
        title: '',
        layout: HomeSectionLayout.promo,
      ),
      HomeFeedSection(
        id: 'categories-horizontal',
        title: 'Browse categories',
        subtitle: 'Scroll sideways — tap to browse',
        layout: HomeSectionLayout.categoriesHorizontal,
        categories: categories,
      ),
      HomeFeedSection(
        id: 'hot-deals',
        title: 'Hot deals',
        subtitle: _hotDealsSubtitle(pool),
        layout: HomeSectionLayout.listingsHorizontal,
        listings: _hotDeals(pool),
        actionLabel: 'See all',
      ),
      HomeFeedSection(
        id: 'trending',
        title: 'Trending',
        subtitle: 'Popular this week',
        layout: HomeSectionLayout.listingsHorizontal,
        listings: _slice(pool, 2, 5),
        actionLabel: 'See all',
      ),
      HomeFeedSection(
        id: 'categories-grid',
        title: 'Shop by category',
        subtitle: 'Tap a category to see all items',
        layout: HomeSectionLayout.categoriesGrid,
        categories: categories,
      ),
      HomeFeedSection(
        id: 'verified-sellers',
        title: 'From verified sellers',
        subtitle: 'Trusted campus sellers',
        layout: HomeSectionLayout.listingsHorizontal,
        listings: pool.where((l) => l.isVerified).take(6).toList(),
        actionLabel: 'See all',
      ),
      HomeFeedSection(
        id: 'near-you',
        title: 'Near you',
        subtitle: 'Listings around campus',
        layout: HomeSectionLayout.listingsGrid,
        listings: pool,
        actionLabel: 'See all',
      ),
    ];
  }

  static HomeFeedSection sectionForId(String id, List<ListingItem> listings) {
    return buildFeed(listings).firstWhere(
      (section) => section.id == id,
      orElse: () => HomeFeedSection(
        id: id,
        title: 'Listings',
        layout: HomeSectionLayout.listingsGrid,
        listings: listings,
      ),
    );
  }

  static List<ListingItem> allListingsForSection(
    String id,
    List<ListingItem> catalog,
  ) {
    if (catalog.isEmpty) return const [];

    return switch (id) {
      'hot-deals' => catalog.where((l) => l.hasActiveDiscount).toList(),
      'trending' => List<ListingItem>.from(catalog)
        ..sort((a, b) => b.reviewCount.compareTo(a.reviewCount)),
      'verified-sellers' => catalog.where((l) => l.isVerified).toList(),
      'near-you' => List<ListingItem>.from(catalog)
        ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm)),
      _ => sectionForId(id, catalog).listings,
    };
  }

  static List<ListingItem> filterByCategory(
    List<HomeFeedSection> sections,
    String? category,
  ) {
    if (category == null || category == 'All') {
      return sections
          .where((s) => s.layout == HomeSectionLayout.listingsGrid)
          .expand((s) => s.listings)
          .toList();
    }
    return sections
        .expand((s) => s.listings)
        .where((l) => l.category == category)
        .toList();
  }

  static String _hotDealsSubtitle(List<ListingItem> pool) {
    final discounted = pool.where((l) => l.hasActiveDiscount).length;
    if (discounted == 0) {
      return 'Campus sellers can add limited-time discounts';
    }
    return 'Limited-time discounts on campus';
  }

  static List<ListingItem> _hotDeals(List<ListingItem> pool) {
    if (pool.isEmpty) return const [];

    final discounted =
        pool.where((l) => l.hasActiveDiscount).take(8).toList();
    if (discounted.length >= 4) return discounted.take(4).toList();

    final filler = pool
        .where((l) => !l.hasActiveDiscount)
        .take(4 - discounted.length)
        .toList();
    return [...discounted, ...filler];
  }

  static List<ListingItem> _slice(
    List<ListingItem> items,
    int start,
    int count,
  ) {
    if (items.isEmpty) return const [];
    final result = <ListingItem>[];
    for (var i = 0; i < count; i++) {
      result.add(items[(start + i) % items.length]);
    }
    return result;
  }
}
