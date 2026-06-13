import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/data/stores/user_session_store.dart';
import '../../../core/models/listing_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/api/session_mode.dart';
import '../../../core/widgets/rating_row.dart';
import '../../../core/widgets/api_client_scope.dart';
import '../../../core/widgets/review_store_scope.dart';
import '../../../core/widgets/skeleton_loaders.dart';
import '../../../core/widgets/user_session_scope.dart';
import '../widgets/review_tile.dart';
import '../widgets/write_review_form.dart';

class ListingReviewsScreen extends StatefulWidget {
  const ListingReviewsScreen({super.key, required this.listing});

  final ListingItem listing;

  @override
  State<ListingReviewsScreen> createState() => _ListingReviewsScreenState();
}

class _ListingReviewsScreenState extends State<ListingReviewsScreen> {
  final _reviewController = TextEditingController();
  int _userRating = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ReviewStoreScope.of(context).loadFromApi(
        ApiClientScope.of(context),
        widget.listing.canonicalId,
      );
    });
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _postReview() async {
    final body = _reviewController.text.trim();
    if (_userRating == 0) {
      _showSnack('Please select a star rating.');
      return;
    }
    if (body.isEmpty) {
      _showSnack('Please write your review.');
      return;
    }

    final session = UserSessionScope.of(context);
    final author = session.currentUser?.fullName ?? 'Campus buyer';

    final error = await ReviewStoreScope.of(context).addReview(
      listingId: widget.listing.canonicalId,
      authorName: author,
      rating: _userRating.toDouble(),
      body: body,
      client: ApiClientScope.of(context),
      isOwnListing: _isOwnListing(session),
    );

    if (!mounted) return;
    if (error != null) {
      _showSnack(error);
      return;
    }

    setState(() {
      _userRating = 0;
      _reviewController.clear();
    });

    _showSnack('Review posted.');
    FocusScope.of(context).unfocus();
  }

  bool _isOwnListing(UserSessionStore session) {
    final user = session.currentUser;
    if (user == null) return false;
    final listing = widget.listing;
    if (listing.sellerUserId.isNotEmpty) {
      return listing.sellerUserId == user.id;
    }
    return listing.sellerName == user.fullName;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviewStore = ReviewStoreScope.of(context);
    final listingId = widget.listing.canonicalId;

    return ListenableBuilder(
      listenable: reviewStore,
      builder: (context, _) {
        final reviews = reviewStore.forListing(listingId);
        final loadingReviews = reviewStore.isLoadingFor(listingId) &&
            reviews.isEmpty &&
            isLiveSession(ApiClientScope.of(context));
        final average = reviewStore.averageRating(listingId);
        final count = reviewStore.reviewCount(listingId);
        final displayRating = count > 0 ? average : widget.listing.rating;
        final displayCount = count > 0 ? count : widget.listing.reviewCount;
        final session = UserSessionScope.of(context);
        final isOwnListing = _isOwnListing(session);

        return Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(LucideIcons.arrowLeft),
            ),
            title: Text('Reviews', style: AppTypography.h3()),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              Text(widget.listing.title, style: AppTypography.bodyBold()),
              const SizedBox(height: 8),
              RatingRow(rating: displayRating, reviewCount: displayCount),
              const SizedBox(height: 20),
              if (isOwnListing)
                Text(
                  'You cannot review your own listing.',
                  style: AppTypography.body(color: AppColors.textSecondary),
                )
              else
                WriteReviewForm(
                  rating: _userRating,
                  controller: _reviewController,
                  onRatingChanged: (value) =>
                      setState(() => _userRating = value),
                  onSubmit: _postReview,
                ),
              if (!isOwnListing) const SizedBox(height: 24),
              if (isOwnListing) const SizedBox(height: 8),
              if (loadingReviews) ...[
                const ReviewTileSkeleton(),
                const SizedBox(height: 12),
                const ReviewTileSkeleton(showDivider: false),
              ] else if (reviews.isEmpty)
                Text(
                  'No reviews yet. Be the first to share your experience.',
                  style: AppTypography.body(color: AppColors.textSecondary),
                )
              else
                ...reviews.asMap().entries.map((entry) {
                  final review = entry.value;
                  return ReviewTile(
                    review: review,
                    showDivider: entry.key < reviews.length - 1,
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
