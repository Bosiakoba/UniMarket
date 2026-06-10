import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/data/mock/mock_profile.dart';
import '../../../core/data/mock/mock_reviews.dart';
import '../../../core/models/listing_item.dart';
import '../../../core/models/listing_review.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/rating_row.dart';
import '../widgets/review_tile.dart';
import '../widgets/write_review_form.dart';

class ListingReviewsScreen extends StatefulWidget {
  const ListingReviewsScreen({super.key, required this.listing});

  final ListingItem listing;

  @override
  State<ListingReviewsScreen> createState() => _ListingReviewsScreenState();
}

class _ListingReviewsScreenState extends State<ListingReviewsScreen> {
  late List<ListingReview> _reviews;
  final _reviewController = TextEditingController();
  int _userRating = 0;

  @override
  void initState() {
    super.initState();
    _reviews = List.of(MockReviews.forListing(widget.listing.id));
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 0;
    final total = _reviews.fold<double>(0, (sum, r) => sum + r.rating);
    return total / _reviews.length;
  }

  void _postReview() {
    final body = _reviewController.text.trim();
    if (_userRating == 0) {
      _showSnack('Please select a star rating.');
      return;
    }
    if (body.isEmpty) {
      _showSnack('Please write your review.');
      return;
    }

    setState(() {
      _reviews.insert(
        0,
        ListingReview(
          id: 'user-${DateTime.now().millisecondsSinceEpoch}',
          authorName: MockProfile.name,
          rating: _userRating.toDouble(),
          body: body,
          dateLabel: 'Just now',
        ),
      );
      _userRating = 0;
      _reviewController.clear();
    });

    _showSnack('Review posted.');
    FocusScope.of(context).unfocus();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listing;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.arrowLeft),
                  ),
                  Expanded(
                    child: Text(
                      'Reviews',
                      textAlign: TextAlign.center,
                      style: AppTypography.h3(),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyBold(),
                  ),
                  const SizedBox(height: 10),
                  RatingRow(
                    rating: _averageRating,
                    reviewCount: _reviews.length,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 16),
                children: [
                  WriteReviewForm(
                    rating: _userRating,
                    controller: _reviewController,
                    onRatingChanged: (value) =>
                        setState(() => _userRating = value),
                    onSubmit: _postReview,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'All reviews (${_reviews.length})',
                    style: AppTypography.bodyBold(),
                  ),
                  const SizedBox(height: 12),
                  if (_reviews.isEmpty)
                    Text(
                      'No reviews yet. Be the first to review.',
                      style: AppTypography.body(
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                    ..._reviews.map(
                      (review) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ReviewTile(
                          review: review,
                          showDivider: false,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
