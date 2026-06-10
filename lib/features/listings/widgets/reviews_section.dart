import 'package:flutter/material.dart';

import '../../../core/data/mock/mock_reviews.dart';
import '../../../core/models/listing_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/rating_row.dart';
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
    final reviews = MockReviews.forListing(listing.id);
    final preview = reviews.take(previewCount).toList();

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
                'See all (${listing.reviewCount})',
                style: AppTypography.caption(
                  color: AppColors.forestGreen,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RatingRow(
          rating: listing.rating,
          reviewCount: listing.reviewCount,
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
  }
}
