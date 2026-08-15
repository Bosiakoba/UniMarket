import '../../constants/market_categories.dart';
import '../../models/home_feed_section.dart';
import '../../models/listing_item.dart';
import '../../models/app_user.dart';

/// Builds the home feed from listing data.
/// Replace [buildFeed] with an API call when the backend is ready.
abstract final class HomeFeedService {
  static List<HomeFeedSection> buildFeed(List<ListingItem> listings, {AppUser? user}) {
    final categories = MarketCategories.listingCategories;
    final pool = listings;
    if (pool.isEmpty) return const [];
    final isGuest = user == null || user.id == 'guest';

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
        layout: HomeSectionLayout.listingsGrid,
        listings: _getHotDeals(pool, isGuest).take(8).toList(),
        actionLabel: 'See all',
      ),
      HomeFeedSection(
        id: 'trending',
        title: 'Trending',
        subtitle: 'Popular this week',
        layout: HomeSectionLayout.listingsGrid,
        listings: _getTrending(pool, isGuest).take(8).toList(),
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
        layout: HomeSectionLayout.listingsGrid,
        listings: _getVerifiedSellers(pool, isGuest).take(8).toList(),
        actionLabel: 'See all',
      ),
      HomeFeedSection(
        id: 'near-you',
        title: 'Near you',
        subtitle: 'Listings around campus',
        layout: HomeSectionLayout.listingsGrid,
        listings: _getNearYou(pool, isGuest, user).take(8).toList(),
        actionLabel: 'See all',
      ),
    ];
  }

  static HomeFeedSection sectionForId(String id, List<ListingItem> listings, {AppUser? user}) {
    return buildFeed(listings, user: user).firstWhere(
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
    List<ListingItem> catalog, {
    AppUser? user,
  }) {
    if (catalog.isEmpty) return const [];
    final isGuest = user == null || user.id == 'guest';

    return switch (id) {
      'hot-deals' => _getHotDeals(catalog, isGuest),
      'trending' => _getTrending(catalog, isGuest),
      'verified-sellers' => _getVerifiedSellers(catalog, isGuest),
      'near-you' => _getNearYou(catalog, isGuest, user),
      _ => sectionForId(id, catalog, user: user).listings,
    };
  }

  static List<ListingItem> filterByCategory(
    List<ListingItem> catalog,
    String? category,
  ) {
    if (category == null || category == 'All') return catalog;
    return catalog.where((l) => l.category == category).toList();
  }

  static String _hotDealsSubtitle(List<ListingItem> pool) {
    final discounted = pool.where((l) => l.hasActiveDiscount).length;
    if (discounted == 0) {
      return 'Campus sellers can add limited-time discounts';
    }
    return 'Limited-time discounts on campus';
  }

  static List<ListingItem> _getHotDeals(List<ListingItem> pool, bool isGuest) {
    final list = pool.where((l) => l.hasActiveDiscount).toList();
    if (isGuest) {
      return list..shuffle();
    }
    list.sort((a, b) {
      if (a.isVerified != b.isVerified) {
        return a.isVerified ? -1 : 1;
      }
      return b.views.compareTo(a.views);
    });
    return list;
  }

  static List<ListingItem> _getTrending(List<ListingItem> pool, bool isGuest) {
    final list = List<ListingItem>.from(pool);
    if (isGuest) {
      return list..shuffle();
    }
    list.sort((a, b) {
      if (a.isVerified != b.isVerified) {
        return a.isVerified ? -1 : 1;
      }
      return b.views.compareTo(a.views);
    });
    return list;
  }

  static List<ListingItem> _getVerifiedSellers(List<ListingItem> pool, bool isGuest) {
    final list = pool.where((l) => l.isVerified).toList();
    if (isGuest) {
      return list..shuffle();
    }
    list.sort((a, b) {
      if (a.hasActiveDiscount != b.hasActiveDiscount) {
        return a.hasActiveDiscount ? -1 : 1;
      }
      return b.views.compareTo(a.views);
    });
    return list;
  }

  static List<ListingItem> _getNearYou(List<ListingItem> pool, bool isGuest, AppUser? user) {
    final list = List<ListingItem>.from(pool);
    if (isGuest || user == null) {
      return list..shuffle();
    }

    final userUni = user.university.trim().toLowerCase();
    final userCampus = user.campus.trim().toLowerCase();

    list.sort((a, b) {
      // 1. Verified priority
      if (a.isVerified != b.isVerified) {
        return a.isVerified ? -1 : 1;
      }

      // 2. Location matching score
      final partsA = a.location.split(' - ');
      final uniA = partsA.first.trim().toLowerCase();
      final campusA = partsA.length > 1 ? partsA[1].trim().toLowerCase() : '';

      final partsB = b.location.split(' - ');
      final uniB = partsB.first.trim().toLowerCase();
      final campusB = partsB.length > 1 ? partsB[1].trim().toLowerCase() : '';

      final scoreA = (uniA == userUni && campusA == userCampus) ? 0
                   : (uniA == userUni) ? 1
                   : 2;
      final scoreB = (uniB == userUni && campusB == userCampus) ? 0
                   : (uniB == userUni) ? 1
                   : 2;

      if (scoreA != scoreB) {
        return scoreA.compareTo(scoreB);
      }

      return b.views.compareTo(a.views);
    });

    return list;
  }
}
