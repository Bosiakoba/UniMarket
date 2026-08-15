import 'package:flutter/material.dart';

import '../../../core/constants/shoe_sizes.dart';
import '../../../core/models/listing_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class ListingShoeSizeBadge extends StatelessWidget {
  const ListingShoeSizeBadge({super.key, required this.listing});

  final ListingItem listing;

  @override
  Widget build(BuildContext context) {
    if (!ShoeSizes.isShoeCategory(listing.category)) {
      return const SizedBox.shrink();
    }

    final label = ShoeSizes.formatDetailed(listing.attributes);
    if (label.isEmpty) return const SizedBox.shrink();

    final itemType = listing.attributes['item_type']?.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.forestGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              listing.attributes['size_value'] ?? '—',
              style: AppTypography.bodyBold(color: AppColors.forestGreen),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Size', style: AppTypography.caption()),
                const SizedBox(height: 2),
                Text(label, style: AppTypography.bodyBold()),
                if (itemType != null && itemType.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(itemType, style: AppTypography.caption()),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ListingAttributeChips extends StatelessWidget {
  const ListingAttributeChips({super.key, required this.listing});

  final ListingItem listing;

  @override
  Widget build(BuildContext context) {
    final entries = _displayEntries(listing);
    if (entries.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            '${entry.$1}: ${entry.$2}',
            style: AppTypography.caption(),
          ),
        );
      }).toList(),
    );
  }

  static List<(String, String)> _displayEntries(ListingItem listing) {
    final attributes = listing.attributes;
    if (attributes.isEmpty) return const [];

    final entries = <(String, String)>[];

    if (ShoeSizes.isShoeCategory(listing.category) &&
        ShoeSizes.isShoeItemType(attributes['item_type'])) {
      for (final key in ['item_type', 'brand', 'model']) {
        final value = attributes[key]?.trim();
        if (value != null && value.isNotEmpty) {
          entries.add((ShoeSizes.labelForAttributeKey(key), value));
        }
      }
      return entries;
    }

    for (final entry in attributes.entries) {
      final key = entry.key;
      final value = entry.value.trim();
      if (value.isEmpty) continue;
      if (ShoeSizes.shouldHideAttributeKey(key)) continue;
      entries.add((ShoeSizes.labelForAttributeKey(key), value));
    }

    return entries;
  }

  static bool hasVisibleEntries(ListingItem listing) =>
      _displayEntries(listing).isNotEmpty;
}
