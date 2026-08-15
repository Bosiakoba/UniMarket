import '../../models/listing_item.dart';
import '../../models/seller_profile.dart';
import 'mock_listings.dart';

abstract final class MockSellers {
  static SellerProfile profileFor(String sellerName, {ListingItem? from}) {
    final listings = listingsBySeller(sellerName);
    final sample = from ?? (listings.isNotEmpty ? listings.first : null);

    return SellerProfile(
      name: sellerName,
      university: _universityFor(sellerName),
      campus: 'Main Campus',
      isVerified: sample?.isVerified ?? false,
      rating: sample?.sellerRating ?? 4.7,
      reviewCount: sample?.sellerReviewCount ?? 12,
      activeListings: listings.length,
      soldCount: _soldCountFor(sellerName),
      memberSince: _memberSinceFor(sellerName),
      phone: _phoneFor(sellerName),
      bio: _bioFor(sellerName),
    );
  }

  static List<ListingItem> listingsBySeller(String sellerName) {
    return MockListings.items
        .where((item) => item.sellerName == sellerName)
        .toList();
  }

  static String _phoneFor(String name) => switch (name) {
        'Ama K.' => '+233 24 111 2233',
        'Kwesi M.' => '+233 55 222 3344',
        'Efua A.' => '+233 20 333 4455',
        'Nana O.' => '+233 27 444 5566',
        'Kojo B.' => '+233 50 555 6677',
        'Yaa S.' => '+233 24 666 7788',
        _ => '+233 50 000 1122',
      };

  static String _universityFor(String name) => switch (name) {
        'Kwesi M.' => 'State University',
        'Efua A.' => 'State University',
        _ => 'State University',
      };

  static int _soldCountFor(String name) => switch (name) {
        'Ama K.' => 18,
        'Kwesi M.' => 24,
        'Efua A.' => 6,
        'Nana O.' => 11,
        'Kojo B.' => 4,
        'Yaa S.' => 15,
        _ => 8,
      };

  static String _memberSinceFor(String name) => switch (name) {
        'Ama K.' => 'Jan 2025',
        'Kwesi M.' => 'Sep 2024',
        _ => 'Mar 2025',
      };

  static String _bioFor(String name) => switch (name) {
        'Ama K.' =>
          'Fashion and hostel essentials. Fast meetups around Main Campus.',
        'Kwesi M.' =>
          'Electronics seller. CS major — laptops, hubs, and accessories.',
        'Efua A.' => 'Fresh produce and snacks for hostel students.',
        'Nana O.' => 'Beauty and personal care items, barely used.',
        'Kojo B.' => 'Textbooks and notes for engineering courses.',
        'Yaa S.' => 'Design services and creative gigs for campus clubs.',
        _ => 'Campus seller on Uni Market.',
      };
}
