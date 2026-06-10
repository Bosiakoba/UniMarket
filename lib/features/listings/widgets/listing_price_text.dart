import 'package:flutter/material.dart';

import '../../../core/models/listing_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class ListingPriceText extends StatelessWidget {
  const ListingPriceText({
    super.key,
    required this.listing,
    this.style,
    this.originalStyle,
    this.compact = false,
  });

  final ListingItem listing;
  final TextStyle? style;
  final TextStyle? originalStyle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final priceStyle = style ?? AppTypography.bodyBold().copyWith(fontSize: 13);

    if (!listing.hasActiveDiscount) {
      return Text(
        listing.formattedPrice,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: priceStyle,
      );
    }

    final original = listing.formattedOriginalPrice;
    final originalTextStyle = (originalStyle ?? AppTypography.caption()).copyWith(
      decoration: TextDecoration.lineThrough,
      color: AppColors.textTertiary,
      fontSize: compact ? 11 : 12,
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            listing.formattedPrice,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: priceStyle.copyWith(color: AppColors.dealRed),
          ),
          if (original != null)
            Text(
              original,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: originalTextStyle,
            ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          listing.formattedPrice,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: priceStyle.copyWith(color: AppColors.dealRed),
        ),
        if (original != null) ...[
          const SizedBox(width: 6),
          Text(
            original,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: originalTextStyle,
          ),
        ],
      ],
    );
  }
}

class ListingDiscountBadge extends StatelessWidget {
  const ListingDiscountBadge({
    super.key,
    required this.listing,
    this.showDaysLeft = true,
  });

  final ListingItem listing;
  final bool showDaysLeft;

  @override
  Widget build(BuildContext context) {
    if (!listing.hasActiveDiscount) return const SizedBox.shrink();

    final percent = listing.discountPercent;
    final label = showDaysLeft
        ? '-$percent% · ${listing.discountDaysRemaining}d left'
        : '-$percent%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.dealRed,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.caption(color: AppColors.white)
            .copyWith(fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }
}
