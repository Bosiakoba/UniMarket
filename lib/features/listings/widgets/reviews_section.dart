import 'package:flutter/material.dart';

import '../../../core/models/listing_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/rating_row.dart';
import '../../../core/widgets/review_store_scope.dart';
import '../screens/listing_reviews_screen.dart';
import 'review_tile.dart';

class ReviewsSection extends StatelessWidget {
  const ReviewsSection({
    super.key,
    required this.listing,
    this.previewCount = 2,
  });

  final ListingItem listing;
  final int previewCount;

  @override
  Widget build(BuildContext context) {
    final reviewStore = ReviewStoreScope.of(context);
    final listingId = listing.canonicalId;

    return ListenableBuilder(
      listenable: reviewStore,
      builder: (context, _) {
        final reviews = reviewStore.forListing(listingId);
        final preview = reviews.take(previewCount).toList();
        final average = reviewStore.averageRating(listingId);
        final count = reviewStore.reviewCount(listingId);
        final displayRating = count > 0 ? average : listing.rating;
        final displayCount = count > 0 ? count : listing.reviewCount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Reviews', style: AppTypography.bodyBold()),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ListingReviewsScreen(listing: listing),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'See all ($displayCount)',
                    style: AppTypography.caption(
                      color: AppColors.forestGreen,
                    ).copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RatingRow(
              rating: displayRating,
              reviewCount: displayCount,
              compact: true,
            ),
            const SizedBox(height: 16),
            ...preview.asMap().entries.map((entry) {
              final index = entry.key;
              final review = entry.value;
              return ReviewTile(
                review: review,
                showDivider: index < preview.length - 1,
              );
            }),
          ],
        );
      },
    );
  }
}
