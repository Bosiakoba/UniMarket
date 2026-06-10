import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/models/listing_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

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
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              listing.imageAsset,
              width: compact ? 48 : 56,
              height: compact ? 48 : 56,
              fit: BoxFit.cover,
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
