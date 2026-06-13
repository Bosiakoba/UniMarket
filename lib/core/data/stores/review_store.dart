import 'package:flutter/foundation.dart';

import '../../api/api_client.dart';
import '../../api/session_mode.dart';
import '../../models/listing_review.dart';
import '../mock/mock_reviews.dart';

class ReviewStore extends ChangeNotifier {
  ReviewStore();

  final Map<String, List<ListingReview>> _byListing = {};
  final Set<String> _loadingListingIds = {};

  bool isLoadingFor(String listingId) =>
      _loadingListingIds.contains(_canonical(listingId));

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
    final id = _canonical(listingId);
    if (!isLiveSession(client)) {
      _seedIfEmpty(listingId);
      return;
    }

    _loadingListingIds.add(id);
    notifyListeners();

    try {
      final reviews = await client.fetchReviews(id);
      _byListing[id] = reviews;
    } catch (_) {
      _byListing[id] = [];
    } finally {
      _loadingListingIds.remove(id);
      notifyListeners();
    }
  }

  Future<String?> addReview({
    required String listingId,
    required String authorName,
    required double rating,
    required String body,
    ApiClient? client,
    bool isOwnListing = false,
  }) async {
    if (isOwnListing) {
      return 'You cannot review your own listing.';
    }

    final id = _canonical(listingId);
    if (client != null && isLiveSession(client)) {
      try {
        await client.postReview(
          listingId: id,
          score: rating.round(),
          comment: body,
        );
        await loadFromApi(client, id);
        return null;
      } catch (error) {
        return error.toString();
      }
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
    return null;
  }

  void clear({bool reseedOfflineMocks = true}) {
    _byListing.clear();
    if (reseedOfflineMocks) {
      for (final listingId in MockReviews.seededListingIds) {
        _byListing[listingId] = List.of(MockReviews.forListing(listingId));
      }
    }
    notifyListeners();
  }

  void _seedIfEmpty(String listingId) {
    final id = _canonical(listingId);
    if (_byListing.containsKey(id)) return;
    _byListing[id] = List.of(MockReviews.forListing(id));
    notifyListeners();
  }

  String _canonical(String listingId) =>
      listingId.endsWith('-dup')
          ? listingId.substring(0, listingId.length - 4)
          : listingId;
}
