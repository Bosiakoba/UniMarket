import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/data/mock/mock_reviews.dart';
import '../../core/data/mock/mock_sellers.dart';
import '../../core/models/listing_item.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../listings/widgets/listing_card.dart';
import '../../core/widgets/rating_row.dart';
import '../../core/widgets/verified_badge.dart';
import '../../core/widgets/message_store_scope.dart';
import '../listings/screens/listing_detail_screen.dart';
import '../listings/screens/listing_reviews_screen.dart';

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
    final profile = MockSellers.profileFor(
      sellerName,
      from: highlightListing,
    );
    final listings = MockSellers.listingsBySeller(sellerName);
    final bottom = MediaQuery.paddingOf(context).bottom;

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
                            profile.initial,
                            style: AppTypography.h1(
                              color: AppColors.forestGreen,
                            ),
                          ),
                        ),
                        if (profile.isVerified)
                          const Positioned(
                            bottom: 0,
                            right: -2,
                            child: VerifiedBadge(compact: true),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(profile.name, style: AppTypography.h2()),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      '${profile.university} · ${profile.campus}',
                      style: AppTypography.caption(),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      'Member since ${profile.memberSince}',
                      style: AppTypography.caption(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: profile.rating.toStringAsFixed(1),
                          label: 'Rating',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          value: '${profile.activeListings}',
                          label: 'Listings',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          value: '${profile.soldCount}',
                          label: 'Sold',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      if (highlightListing != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ListingReviewsScreen(
                              listing: highlightListing!,
                            ),
                          ),
                        );
                      }
                    },
                    child: RatingRow(
                      rating: profile.rating,
                      reviewCount: profile.reviewCount,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(profile.bio, style: AppTypography.body()),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.clock,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        profile.responseTime,
                        style: AppTypography.caption(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => MessageStoreScope.of(context)
                              .navigateToSellerChat(
                            context,
                            sellerName: sellerName,
                            listing: highlightListing,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.forestGreen,
                            minimumSize: const Size.fromHeight(46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Message',
                            style: AppTypography.button(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text('Call', style: AppTypography.bodyBold()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Listings from ${profile.name}',
                    style: AppTypography.bodyBold(),
                  ),
                  const SizedBox(height: 12),
                  if (listings.isEmpty)
                    Text(
                      'No active listings',
                      style: AppTypography.body(color: AppColors.textSecondary),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: ListingGrid.gridDelegate,
                      itemCount: listings.length,
                      itemBuilder: (context, index) {
                        final listing = listings[index];
                        return ListingCard(
                          listing: listing,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ListingDetailScreen(listing: listing),
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                  Text('Recent feedback', style: AppTypography.bodyBold()),
                  const SizedBox(height: 12),
                  ...MockReviews.forListing(highlightListing?.id ?? '1')
                      .take(2)
                      .map(
                        (review) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  review.authorName,
                                  style: AppTypography.bodyBold(),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  review.body,
                                  style: AppTypography.body(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 12),
              child: Text(
                profile.phone,
                textAlign: TextAlign.center,
                style: AppTypography.caption(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(value, style: AppTypography.bodyBold()),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.caption()),
        ],
      ),
    );
  }
}
