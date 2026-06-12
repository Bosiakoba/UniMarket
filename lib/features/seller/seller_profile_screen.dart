import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/api/session_mode.dart';
import '../../core/models/listing_item.dart';
import '../../core/navigation/listing_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/api_client_scope.dart';
import '../../core/widgets/message_store_scope.dart';
import '../../core/widgets/rating_row.dart';
import '../../core/widgets/seller_store_scope.dart';
import '../../core/widgets/user_session_scope.dart';
import '../../core/widgets/verified_badge.dart';
import '../listings/screens/listing_reviews_screen.dart';
import 'widgets/seller_listing_tile.dart';

enum _SellerListingFilter { all, active, unavailable }

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({
    super.key,
    required this.sellerName,
    this.highlightListing,
  });

  final String sellerName;
  final ListingItem? highlightListing;

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  _SellerListingFilter _filter = _SellerListingFilter.active;

  void _openListing(BuildContext context, ListingItem listing) {
    ListingNavigation.openDetail(
      context,
      listing: listing,
      catalog: SellerStoreScope.of(context),
    );
  }

  List<ListingItem> _visibleListings(List<ListingItem> listings) {
    return switch (_filter) {
      _SellerListingFilter.all => listings,
      _SellerListingFilter.active =>
        listings.where((listing) => listing.isBrowseable).toList(),
      _SellerListingFilter.unavailable =>
        listings.where((listing) => !listing.isBrowseable).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final sellerStore = SellerStoreScope.of(context);
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
              child: ListenableBuilder(
                listenable: sellerStore,
                builder: (context, _) {
                  final listings =
                      sellerStore.listingsForSeller(widget.sellerName);
                  final activeListings =
                      listings.where((listing) => listing.isBrowseable).toList();
                  final inactiveListings =
                      listings.where((listing) => !listing.isBrowseable).toList();
                  final visible = _visibleListings(listings);
                  final profileListing =
                      widget.highlightListing ?? listings.firstOrNull;
                  final isVerified = profileListing?.isVerified ?? false;
                  final rating = profileListing?.sellerRating ??
                      profileListing?.rating ??
                      0;
                  final reviewCount = profileListing?.sellerReviewCount ??
                      profileListing?.reviewCount ??
                      0;
                  final initial = widget.sellerName.isNotEmpty
                      ? widget.sellerName[0].toUpperCase()
                      : '?';

                  return ListView(
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
                        widget.sellerName,
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
                        _listingSummary(
                          activeCount: activeListings.length,
                          totalCount: listings.length,
                        ),
                        textAlign: TextAlign.center,
                        style:
                            AppTypography.body(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                MessageStoreScope.of(context)
                                    .navigateToSellerChat(
                                  context,
                                  sellerName: widget.sellerName,
                                  listing: profileListing,
                                  client: ApiClientScope.of(context),
                                  currentUserId: UserSessionScope.of(context)
                                      .currentUser
                                      ?.id,
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
                      Row(
                        children: [
                          Text('Listings', style: AppTypography.h3()),
                          const Spacer(),
                          if (listings.isNotEmpty)
                            Text(
                              '${activeListings.length} active',
                              style: AppTypography.caption(
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (listings.isNotEmpty)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _FilterChip(
                                label: 'Active',
                                count: activeListings.length,
                                selected:
                                    _filter == _SellerListingFilter.active,
                                onTap: () => setState(
                                  () => _filter = _SellerListingFilter.active,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'All',
                                count: listings.length,
                                selected: _filter == _SellerListingFilter.all,
                                onTap: () => setState(
                                  () => _filter = _SellerListingFilter.all,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _FilterChip(
                                label: 'Unavailable',
                                count: inactiveListings.length,
                                selected: _filter ==
                                    _SellerListingFilter.unavailable,
                                onTap: () => setState(
                                  () =>
                                      _filter = _SellerListingFilter.unavailable,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      if (listings.isEmpty)
                        Text(
                          isLiveSession(ApiClientScope.of(context))
                              ? 'No listings from this seller yet.'
                              : 'No listings found for this seller.',
                          style:
                              AppTypography.body(color: AppColors.textSecondary),
                        )
                      else if (visible.isEmpty)
                        Text(
                          _emptyFilterMessage(_filter),
                          style:
                              AppTypography.body(color: AppColors.textSecondary),
                        )
                      else if (_filter == _SellerListingFilter.all) ...[
                        if (activeListings.isNotEmpty) ...[
                          _SectionLabel(
                            title: 'Active',
                            count: activeListings.length,
                          ),
                          const SizedBox(height: 8),
                          ..._listingTiles(
                            context,
                            activeListings,
                          ),
                        ],
                        if (inactiveListings.isNotEmpty) ...[
                          if (activeListings.isNotEmpty)
                            const SizedBox(height: 16),
                          _SectionLabel(
                            title: 'Unavailable',
                            count: inactiveListings.length,
                          ),
                          const SizedBox(height: 8),
                          ..._listingTiles(
                            context,
                            inactiveListings,
                          ),
                        ],
                      ] else
                        ..._listingTiles(context, visible),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: bottom),
          ],
        ),
      ),
    );
  }

  String _listingSummary({
    required int activeCount,
    required int totalCount,
  }) {
    if (totalCount == 0) return 'No campus listings yet';
    if (activeCount == totalCount) {
      return '$activeCount active campus listing${activeCount == 1 ? '' : 's'}';
    }
    return '$activeCount active · $totalCount total';
  }

  String _emptyFilterMessage(_SellerListingFilter filter) {
    return switch (filter) {
      _SellerListingFilter.active => 'No active listings right now.',
      _SellerListingFilter.unavailable => 'No sold or paused listings.',
      _SellerListingFilter.all => 'No listings found.',
    };
  }

  List<Widget> _listingTiles(
    BuildContext context,
    List<ListingItem> listings,
  ) {
    return [
      for (var i = 0; i < listings.length; i++) ...[
        if (i > 0) const SizedBox(height: 8),
        SellerListingTile(
          listing: listings[i],
          onTap: () => _openListing(context, listings[i]),
        ),
      ],
    ];
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$title ($count)',
      style: AppTypography.caption(
        color: AppColors.textSecondary,
      ).copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.black : AppColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? AppColors.black : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.caption(
                color: selected ? AppColors.white : AppColors.textPrimary,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.white.withValues(alpha: 0.2)
                      : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: AppTypography.caption(
                    color: selected ? AppColors.white : AppColors.textSecondary,
                  ).copyWith(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
