import '../../models/listing_review.dart';

abstract final class MockReviews {
  static const _defaultReviews = [
    ListingReview(
      id: 'r1',
      authorName: 'Jordan K.',
      rating: 5,
      body: 'Exactly as described. Quick meetup at the library.',
      dateLabel: '2 days ago',
    ),
    ListingReview(
      id: 'r2',
      authorName: 'Sam R.',
      rating: 4.5,
      body: 'Good condition, fair price. Seller was easy to reach.',
      dateLabel: '1 week ago',
    ),
    ListingReview(
      id: 'r3',
      authorName: 'Efua A.',
      rating: 5,
      body: 'Would buy from this seller again. Very responsive.',
      dateLabel: '2 weeks ago',
    ),
    ListingReview(
      id: 'r4',
      authorName: 'Kojo B.',
      rating: 4,
      body: 'Item matched the photos. Pickup was smooth on campus.',
      dateLabel: '3 weeks ago',
    ),
    ListingReview(
      id: 'r5',
      authorName: 'Yaa S.',
      rating: 4.5,
      body: 'Honest listing and friendly seller. Recommended.',
      dateLabel: '1 month ago',
    ),
  ];

  static List<ListingReview> forListing(String listingId) {
    return _defaultReviews;
  }
}
