import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/api/session_mode.dart';
import '../../core/models/listing_item.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/api_client_scope.dart';
import '../../core/widgets/message_store_scope.dart';
import '../../core/widgets/rating_row.dart';
import '../../core/widgets/seller_store_scope.dart';
import '../../core/widgets/user_session_scope.dart';
import '../../core/widgets/verified_badge.dart';
import '../listings/screens/listing_detail_screen.dart';
import '../listings/screens/listing_reviews_screen.dart';
import '../listings/widgets/listing_card.dart';

class SellerProfileScreen extends StatelessWidget {
  const SellerProfileScreen({
    super.key,
    required this.sellerName,
    this.highlightListing,
  });

  final String sellerName;
  final ListingItem? highlightListing;

  @override
  Widget build(BuildContext context) {
    final sellerStore = SellerStoreScope.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final listings = sellerStore.listingsForSeller(sellerName);
    final profileListing = highlightListing ?? listings.firstOrNull;
    final isVerified = profileListing?.isVerified ?? false;
    final rating = profileListing?.sellerRating ?? profileListing?.rating ?? 0;
    final reviewCount =
        profileListing?.sellerReviewCount ?? profileListing?.reviewCount ?? 0;
    final initial =
        sellerName.isNotEmpty ? sellerName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.arrowLeft),
                  ),
                  Expanded(
                    child: Text(
                      'Seller profile',
                      textAlign: TextAlign.center,
                      style: AppTypography.h3(),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.surfaceMuted,
                          child: Text(
                            initial,
                            style: AppTypography.h1(
                              color: AppColors.forestGreen,
                            ),
                          ),
                        ),
                        if (isVerified)
                          const Positioned(
                            right: -2,
                            bottom: -2,
                            child: VerifiedBadge(compact: true),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    sellerName,
                    textAlign: TextAlign.center,
                    style: AppTypography.h2(),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: RatingRow(
                      rating: rating,
                      reviewCount: reviewCount,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${listings.length} active campus listings',
                    textAlign: TextAlign.center,
                    style: AppTypography.body(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            MessageStoreScope.of(context).navigateToSellerChat(
                              context,
                              sellerName: sellerName,
                              listing: profileListing,
                              client: ApiClientScope.of(context),
                              currentUserId:
                                  UserSessionScope.of(context).currentUser?.id,
                            );
                          },
                          child: const Text('Message seller'),
                        ),
                      ),
                      if (profileListing != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => ListingReviewsScreen(
                                    listing: profileListing,
                                  ),
                                ),
                              );
                            },
                            child: const Text('Reviews'),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Listings', style: AppTypography.h3()),
                  const SizedBox(height: 12),
                  if (listings.isEmpty)
                    Text(
                      isLiveSession(ApiClientScope.of(context))
                          ? 'No live listings from this seller yet.'
                          : 'No listings found for this seller.',
                      style: AppTypography.body(color: AppColors.textSecondary),
                    )
                  else
                    ...listings.map(
                      (listing) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ListingCard(
                          listing: listing,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ListingDetailScreen(listing: listing),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: bottom),
          ],
        ),
      ),
    );
  }
}
