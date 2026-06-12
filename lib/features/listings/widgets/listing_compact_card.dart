import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/shoe_sizes.dart';
import '../../../core/auth/auth_gate.dart';
import '../../../core/models/listing_item.dart';
import '../../../core/navigation/listing_navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/api_client_scope.dart';
import '../../../core/widgets/listing_image.dart';
import '../../../core/widgets/seller_store_scope.dart';
import '../../../core/widgets/wishlist_store_scope.dart';
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
    final wishlist = WishlistStoreScope.of(context);
    final listingId = listing.canonicalId;

    return ListenableBuilder(
      listenable: wishlist,
      builder: (context, _) {
        final saved = wishlist.contains(listingId);

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
                        child: ListingImage(
                          source: listing.primaryPhotoSource,
                          fit: BoxFit.cover,
                          cacheWidth: 280,
                          borderRadius: BorderRadius.circular(12),
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
                              style:
                                  AppTypography.caption(color: AppColors.white)
                                      .copyWith(fontSize: 10),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 6,
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
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              saved ? Icons.favorite : LucideIcons.heart,
                              size: saved ? 13 : 12,
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
            if (ShoeSizes.isShoeCategory(listing.category) &&
                ShoeSizes.formatPrimary(listing.attributes).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  ShoeSizes.formatDetailed(listing.attributes),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(color: AppColors.forestGreen)
                      .copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ListingPriceText(listing: listing, compact: true),
              ],
            ),
          ),
        );
      },
    );
  }
}
