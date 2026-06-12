import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/models/listing_availability.dart';
import '../../../core/models/listing_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/listing_image.dart';
import '../../listings/widgets/listing_price_text.dart';

class SellerListingTile extends StatelessWidget {
  const SellerListingTile({
    super.key,
    required this.listing,
    required this.onTap,
  });

  final ListingItem listing;
  final VoidCallback onTap;

  static String statusLabel(ListingItem listing) {
    if (listing.isBrowseable) return listing.availabilityLabel;
    return switch (listing.lifecycleStatus) {
      ListingLifecycleStatus.sold => 'Sold',
      ListingLifecycleStatus.soldOut => 'Sold out',
      ListingLifecycleStatus.paused => 'Paused',
      ListingLifecycleStatus.active => 'Active',
    };
  }

  @override
  Widget build(BuildContext context) {
    final inactive = !listing.isBrowseable;

    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Opacity(
                opacity: inactive ? 0.55 : 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ListingImage(
                    source: listing.primaryPhotoSource,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    cacheWidth: 140,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyBold(),
                    ),
                    const SizedBox(height: 6),
                    _StatusPill(
                      label: statusLabel(listing),
                      inactive: inactive,
                    ),
                    const SizedBox(height: 4),
                    ListingPriceText(
                      listing: listing,
                      style: AppTypography.price().copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      listing.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption(),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.inactive});

  final String label;
  final bool inactive;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: inactive
              ? AppColors.textTertiary.withValues(alpha: 0.14)
              : AppColors.forestGreen.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption(
            color: inactive ? AppColors.textSecondary : AppColors.forestGreen,
          ).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
