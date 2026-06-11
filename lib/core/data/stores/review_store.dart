import 'package:flutter/foundation.dart';

import '../../api/api_client.dart';
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
    final id = _canonical(listingId);
    return List.unmodifiable(_byListing[id] ?? const []);
  }

  double averageRating(String listingId) {
    final reviews = _byListing[_canonical(listingId)];
    if (reviews == null || reviews.isEmpty) return 0;
    final total = reviews.fold<double>(0, (sum, r) => sum + r.rating);
    return total / reviews.length;
  }

  int reviewCount(String listingId) =>
      _byListing[_canonical(listingId)]?.length ?? 0;

  Future<void> loadFromApi(ApiClient client, String listingId) async {
    try {
      final reviews = await client.fetchReviews(_canonical(listingId));
      _byListing[_canonical(listingId)] = reviews;
      notifyListeners();
    } catch (_) {
      // Keep seeded/local reviews.
    }
  }

  Future<void> addReview({
    required String listingId,
    required String authorName,
    required double rating,
    required String body,
    ApiClient? client,
  }) async {
    final id = _canonical(listingId);
    if (client != null) {
      try {
        await client.postReview(
          listingId: id,
          score: rating.round(),
          comment: body,
        );
        await loadFromApi(client, id);
        return;
      } catch (_) {}
    }

    final review = ListingReview(
      id: 'review-${DateTime.now().millisecondsSinceEpoch}',
      authorName: authorName,
      rating: rating,
      body: body,
      dateLabel: 'Just now',
    );
    _byListing.putIfAbsent(id, () => []).insert(0, review);
    notifyListeners();
  }

  void clear() {
    _byListing.clear();
    for (final listingId in MockReviews.seededListingIds) {
      _byListing[listingId] = List.of(MockReviews.forListing(listingId));
    }
    notifyListeners();
  }

  String _canonical(String listingId) =>
      listingId.endsWith('-dup') ? listingId.substring(0, listingId.length - 4) : listingId;
}
