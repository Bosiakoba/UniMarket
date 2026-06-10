import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/models/listing_item.dart';
import '../../../core/navigation/listing_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/seller_store_scope.dart';
import 'listing_price_text.dart';

class ListingCompactCard extends StatelessWidget {
  const ListingCompactCard({
    super.key,
    required this.listing,
    this.width = 140,
    this.height = homeListingRowHeight,
  });

  static const double homeListingRowHeight = 188;

  final ListingItem listing;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: GestureDetector(
        onTap: () => ListingNavigation.openDetail(
          context,
          listing: listing,
          catalog: SellerStoreScope.of(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        listing.imageAsset,
                        fit: BoxFit.cover,
                        cacheWidth: 280,
                      ),
                    ),
                  ),
                  if (listing.hasActiveDiscount)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: ListingDiscountBadge(
                        listing: listing,
                        showDaysLeft: false,
                      ),
                    )
                  else if (listing.isVerified)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.black.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Verified',
                          style: AppTypography.caption(color: AppColors.white)
                              .copyWith(fontSize: 10),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.heart,
                        size: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              listing.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption(color: AppColors.textSecondary)
                  .copyWith(fontSize: 12),
            ),
            const SizedBox(height: 2),
            ListingPriceText(listing: listing, compact: true),
          ],
        ),
      ),
    );
  }
}
