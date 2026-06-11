import 'package:flutter/foundation.dart';

import '../../models/listing_review.dart';
import '../mock/mock_reviews.dart';

class ReviewStore extends ChangeNotifier {
  ReviewStore() {
    for (final listingId in MockReviews.seededListingIds) {
      _byListing[listingId] = List.of(MockReviews.forListing(listingId));
    }
  }

  final Map<String, List<ListingReview>> _byListing = {};

  List<ListingReview> forListing(String listingId) {
    return List.unmodifiable(_byListing[listingId] ?? const []);
  }

  double averageRating(String listingId) {
    final reviews = _byListing[listingId];
    if (reviews == null || reviews.isEmpty) return 0;
    final total = reviews.fold<double>(0, (sum, r) => sum + r.rating);
    return total / reviews.length;
  }

  int reviewCount(String listingId) => _byListing[listingId]?.length ?? 0;

  void addReview({
    required String listingId,
    required String authorName,
    required double rating,
    required String body,
  }) {
    final review = ListingReview(
      id: 'review-${DateTime.now().millisecondsSinceEpoch}',
      authorName: authorName,
      rating: rating,
      body: body,
      dateLabel: 'Just now',
    );
    _byListing.putIfAbsent(listingId, () => []).insert(0, review);
    notifyListeners();
  }

  void clear() {
    _byListing.clear();
    for (final listingId in MockReviews.seededListingIds) {
      _byListing[listingId] = List.of(MockReviews.forListing(listingId));
    }
    notifyListeners();
  }
}
