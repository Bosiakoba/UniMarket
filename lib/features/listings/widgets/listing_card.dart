import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ListingImage(
                        source: listing.imageAsset,
                        fit: BoxFit.cover,
                        cacheWidth: 280,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    if (listing.hasActiveDiscount)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: ListingDiscountBadge(listing: listing),
                      ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () => wishlist.toggle(
                          listingId,
                          client: ApiClientScope.of(context),
                        ),
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
                            color: saved
                                ? AppColors.dealRed
                                : AppColors.textPrimary,
                          ),
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
              ListingPriceText(listing: listing),
            ],
          ),
        );
      },
    );
  }
}

abstract final class ListingGrid {
  static const SliverGridDelegateWithFixedCrossAxisCount sliverDelegate =
      SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 0.92,
  );

  static const SliverGridDelegateWithFixedCrossAxisCount gridDelegate =
      sliverDelegate;
}
