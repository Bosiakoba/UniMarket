import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class RatingRow extends StatelessWidget {
  const RatingRow({
    super.key,
    required this.rating,
    required this.reviewCount,
    this.compact = false,
  });

  final double rating;
  final int reviewCount;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (reviewCount == 0) {
      return Row(
        children: [
          ...List.generate(
            5,
            (_) => Icon(
              LucideIcons.star,
              size: compact ? 14 : 16,
              color: AppColors.border,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'No reviews yet',
            style: compact
                ? AppTypography.caption(color: AppColors.textSecondary)
                : AppTypography.body(color: AppColors.textSecondary),
          ),
        ],
      );
    }

    return Row(
      children: [
        ...List.generate(5, (i) {
          final filled = i < rating.round();
          return Icon(
            LucideIcons.star,
            size: compact ? 14 : 16,
            color: filled ? AppColors.verifiedGold : AppColors.border,
          );
        }),
        const SizedBox(width: 6),
        Text(
          rating.toStringAsFixed(1),
          style: compact
              ? AppTypography.caption().copyWith(fontWeight: FontWeight.w600)
              : AppTypography.bodyBold(),
        ),
        const SizedBox(width: 4),
        Text(
          '($reviewCount reviews)',
          style: AppTypography.caption(),
        ),
      ],
    );
  }
}
