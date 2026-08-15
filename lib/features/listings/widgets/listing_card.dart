import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/auth/auth_gate.dart';
import '../../../core/data/stores/wishlist_store.dart';
import '../../../core/models/listing_item.dart';
import '../../../core/navigation/listing_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/api_client_scope.dart';
import '../../../core/widgets/listing_image.dart';
import '../../../core/widgets/seller_store_scope.dart';
import '../../../core/widgets/wishlist_store_scope.dart';
import 'listing_price_text.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    this.onTap,
  });

  final ListingItem listing;
  final VoidCallback? onTap;

  void _openDetail(BuildContext context) {
    ListingNavigation.openDetail(
      context,
      listing: listing,
      catalog: SellerStoreScope.of(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = WishlistStoreScope.of(context);
    final listingId = listing.canonicalId;

    return ListenableBuilder(
      listenable: wishlist,
      builder: (context, _) {
        final saved = wishlist.contains(listingId);
        return GestureDetector(
          onTap: onTap ?? () => _openDetail(context),
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: Colors.grey.shade300, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _ListingCardImage(
                  listing: listing,
                  saved: saved,
                  listingId: listingId,
                  wishlist: wishlist,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.formattedPrice,
                        style: AppTypography.h3(color: AppColors.forestGreen)
                            .copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        listing.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(color: AppColors.textPrimary)
                            .copyWith(fontSize: 13, fontWeight: FontWeight.w400, height: 1.2),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          listing.distanceLabel,
                          if (listing.attributes['Condition'] != null) listing.attributes['Condition']!,
                          ...listing.attributes.entries.where((e) => e.key != 'Condition').take(2).map((e) => e.value),
                        ].join(' • '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption(color: AppColors.textTertiary)
                            .copyWith(fontSize: 11, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ListingCardImage extends StatelessWidget {
  const _ListingCardImage({
    required this.listing,
    required this.saved,
    required this.listingId,
    required this.wishlist,
  });

  final ListingItem listing;
  final bool saved;
  final String listingId;
  final WishlistStore wishlist;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListingImage(
          source: listing.primaryPhotoSource,
          fit: BoxFit.contain,
          cacheWidth: 300,
          borderRadius: BorderRadius.zero,
        ),
        if (listing.hasActiveDiscount)
          Positioned(
            top: 6,
            left: 6,
            child: ListingDiscountBadge(listing: listing),
          ),
        if (listing.isVerified)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_user, size: 12, color: Color(0xFF0D47A1)),
                  const SizedBox(width: 4),
                  Text(
                    'Verified ID',
                    style: AppTypography.caption(color: const Color(0xFF0D47A1))
                        .copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          bottom: 6,
          right: 6,
          child: GestureDetector(
            onTap: () async {
              final allowed = await ensureRegisteredAccount(
                context,
                reason: 'Sign in to save campus deals to your wishlist.',
              );
              if (!context.mounted || !allowed) return;
              await wishlist.toggle(
                listingId,
                client: ApiClientScope.of(context),
              );
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                saved ? Icons.favorite : LucideIcons.heart,
                size: saved ? 14 : 13,
                color: saved ? AppColors.dealRed : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

abstract final class ListingGrid {
  /// Returns a responsive column count based on available width.
  static int responsiveColumns(double width) {
    if (width >= 1400) {
      return 6;
    } else if (width >= 1100) {
      return 5;
    } else if (width >= 900) {
      return 4;
    } else if (width >= 600) {
      return 3;
    } else {
      return 2;
    }
  }
}
