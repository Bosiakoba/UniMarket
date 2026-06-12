import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/models/listing_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/listing_image.dart';

class ListingAttachmentCard extends StatelessWidget {
  const ListingAttachmentCard({
    super.key,
    required this.listing,
    this.onRemove,
    this.compact = false,
  });

  final ListingItem listing;
  final VoidCallback? onRemove;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final thumbSize = compact ? 48.0 : 56.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: thumbSize,
            height: thumbSize,
            child: ListingImage(
              source: listing.primaryPhotoSource,
              width: thumbSize,
              height: thumbSize,
              fit: BoxFit.cover,
              borderRadius: BorderRadius.circular(10),
              cacheWidth: 120,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attached listing',
                  style: AppTypography.caption(color: AppColors.forestGreen),
                ),
                const SizedBox(height: 2),
                Text(
                  listing.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyBold(),
                ),
                Text(
                  listing.formattedPrice,
                  style: AppTypography.caption(),
                ),
                Text(
                  'Listing #${listing.canonicalId}',
                  style: AppTypography.caption(color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          if (onRemove != null)
            IconButton(
              onPressed: onRemove,
              icon: const Icon(LucideIcons.x, size: 18),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
