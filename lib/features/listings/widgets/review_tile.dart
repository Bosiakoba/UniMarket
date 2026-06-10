import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/models/listing_review.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class ReviewTile extends StatelessWidget {
  const ReviewTile({
    super.key,
    required this.review,
    this.showDivider = true,
  });

  final ListingReview review;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceMuted,
              child: Text(
                review.authorInitial,
                style: AppTypography.caption(color: AppColors.forestGreen),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          review.authorName,
                          style: AppTypography.bodyBold(),
                        ),
                      ),
                      Text(review.dateLabel, style: AppTypography.caption()),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _StarRating(rating: review.rating),
                  const SizedBox(height: 6),
                  Text(review.body, style: AppTypography.body()),
                ],
              ),
            ),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final filled = i < rating.round();
        return Icon(
          LucideIcons.star,
          size: 13,
          color: filled ? AppColors.verifiedGold : AppColors.border,
        );
      }),
    );
  }
}
