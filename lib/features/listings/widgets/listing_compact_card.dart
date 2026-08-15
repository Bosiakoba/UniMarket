import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
                        ),
                      if (listing.isVerified || (listing.sellerRating > 0 && listing.sellerReviewCount > 0))
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (listing.isVerified)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  margin: const EdgeInsets.only(bottom: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.verifiedGold,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Verified ID',
                                    style: AppTypography.caption(color: AppColors.forestGreenDeep)
                                        .copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              if (listing.sellerRating > 0 && listing.sellerReviewCount > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.black.withValues(alpha: 0.72),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star, size: 10, color: AppColors.verifiedGold),
                                      const SizedBox(width: 2),
                                      Text(
                                        listing.sellerRating.toStringAsFixed(1),
                                        style: AppTypography.caption(color: AppColors.white)
                                            .copyWith(fontSize: 10, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(6, 16, 36, 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                AppColors.black.withValues(alpha: 0.95),
                                AppColors.black.withValues(alpha: 0.7),
                                AppColors.black.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Located Area: ${listing.distanceLabel == '0.0 km' ? 'Main Campus' : listing.distanceLabel}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption(color: AppColors.white.withValues(alpha: 0.8))
                                    .copyWith(fontSize: 8),
                              ),
                              const SizedBox(height: 2),
                              Builder(
                                builder: (context) {
                                  final attributesText = listing.attributes.entries
                                      .where((e) => e.key != 'Condition')
                                      .take(2)
                                      .map((e) => e.value)
                                      .join(', ');
                                  final subtitleText = attributesText.isNotEmpty
                                      ? '${listing.title} • $attributesText'
                                      : listing.title;
                                  return Text(
                                    subtitleText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption(color: AppColors.white)
                                        .copyWith(fontSize: 10, fontWeight: FontWeight.w600),
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      listing.formattedPrice,
                                      style: AppTypography.h3(color: AppColors.forestGreen)
                                          .copyWith(fontSize: 12, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.forestGreen,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(LucideIcons.phone, size: 8, color: AppColors.white),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Call',
                                          style: AppTypography.caption(color: AppColors.white)
                                              .copyWith(fontSize: 9, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
                  style: AppTypography.body(color: AppColors.textPrimary)
                      .copyWith(fontSize: 13, fontWeight: FontWeight.w600),
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
              )
            else if (listing.attributes.entries.where((e) => e.key != 'Condition').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  listing.attributes.entries
                      .where((e) => e.key != 'Condition')
                      .take(3)
                      .map((e) => e.value)
                      .join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(color: AppColors.textSecondary)
                      .copyWith(fontSize: 10),
                ),
              ),
            ListingPriceText(listing: listing, compact: true),
            const SizedBox(height: 4),
            Row(
              children: [
                if (listing.attributes['Condition'] != null || listing.tags.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      listing.attributes['Condition'] ?? listing.tags.first,
                      style: AppTypography.caption(color: AppColors.textSecondary)
                          .copyWith(fontSize: 9, fontWeight: FontWeight.w600),
                    ),
                  ),
                const Spacer(),
                const Icon(LucideIcons.mapPin, size: 10, color: AppColors.textTertiary),
                const SizedBox(width: 2),
                Text(
                  listing.distanceLabel,
                  style: AppTypography.caption(color: AppColors.textTertiary)
                      .copyWith(fontSize: 10),
                ),
              ],
            ),
              ],
            ),
          ),
        );
      },
    );
  }
}
