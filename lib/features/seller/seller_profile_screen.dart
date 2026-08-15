import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/session_mode.dart';
import '../../core/api/media_url.dart';
import '../../core/models/listing_item.dart';
import '../../core/navigation/listing_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/api_client_scope.dart';
import '../../core/widgets/message_store_scope.dart';
import '../../core/widgets/rating_row.dart';
import '../../core/models/app_user.dart';
import '../../core/widgets/seller_store_scope.dart';
import '../../core/widgets/user_session_scope.dart';
import '../../core/widgets/verified_badge.dart';
import '../listings/screens/listing_reviews_screen.dart';
import 'widgets/seller_listing_tile.dart';
import 'followers_screen.dart';
import 'following_screen.dart';
import '../../core/auth/auth_gate.dart';

enum _SellerListingFilter { all, active }

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
  AppUser? _sellerUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUser();
    });
  }

  Future<void> _loadUser() async {
    final listings = SellerStoreScope.of(context).listingsForSeller(widget.sellerName);
    final profileListing = widget.highlightListing ?? listings.firstOrNull;
    final client = ApiClientScope.of(context);
    
    if (profileListing != null && profileListing.sellerUserId.isNotEmpty && isLiveSession(client)) {
      try {
        final user = await client.getUser(profileListing.sellerUserId);
        if (mounted) {
          setState(() {
            _sellerUser = user;
          });
        }
      } catch (e) {
        _loadMockUser(profileListing);
      }
    } else {
      _loadMockUser(profileListing);
    }
  }

  void _loadMockUser(ListingItem? profileListing) {
    if (mounted) {
      setState(() {
        _sellerUser = AppUser(
          id: profileListing?.sellerUserId.isNotEmpty == true 
              ? profileListing!.sellerUserId 
              : 'mock-${widget.sellerName.toLowerCase().replaceAll(' ', '-')}',
          email: '${widget.sellerName.toLowerCase().replaceAll(' ', '')}@university.edu',
          fullName: widget.sellerName,
          university: profileListing?.location ?? 'State University',
          campus: 'Main Campus',
          isSeller: true,
          isVerified: profileListing?.isVerified ?? false,
          followersCount: profileListing?.sellerReviewCount ?? 12,
          followingCount: 15,
          isFollowing: false,
        );
      });
    }
  }

  Future<void> _toggleFollow() async {
    final allowed = await ensureRegisteredAccount(context, reason: 'Sign in to follow sellers.');
    if (!mounted || !allowed) return;
    if (_sellerUser == null) return;
    
    final client = ApiClientScope.of(context);
    final wasFollowing = _sellerUser!.isFollowing;
    
    setState(() {
      _sellerUser = _sellerUser!.copyWith(
        isFollowing: !wasFollowing,
        followersCount: _sellerUser!.followersCount + (wasFollowing ? -1 : 1),
      );
    });
    
    if (isLiveSession(client) && !_sellerUser!.id.startsWith('mock-')) {
      try {
        if (wasFollowing) {
          await client.unfollowUser(_sellerUser!.id);
        } else {
          await client.followUser(_sellerUser!.id);
        }
      } catch (e) {
        // Revert on error
        if (mounted) {
          setState(() {
            _sellerUser = _sellerUser!.copyWith(
              isFollowing: wasFollowing,
              followersCount: _sellerUser!.followersCount + (wasFollowing ? 1 : -1),
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update follow status')),
          );
        }
      }
    }
  }

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
                  final rating = profileListing?.sellerRating ?? 0;
                  final reviewCount = profileListing?.sellerReviewCount ?? 0;
                  final initial = widget.sellerName.isNotEmpty
                      ? widget.sellerName[0].toUpperCase()
                      : '?';
                  
                  final followerCount = _sellerUser?.followersCount ?? 0;
                  final followingCount = _sellerUser?.followingCount ?? 0;
                  final isFollowing = _sellerUser?.isFollowing ?? false;
                  final isMe = _sellerUser?.id == UserSessionScope.of(context).currentUser?.id;

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
                              backgroundImage: profileListing?.sellerAvatarUrl != null && profileListing!.sellerAvatarUrl!.isNotEmpty
                                  ? NetworkImage(MediaUrlResolver.resolve(profileListing.sellerAvatarUrl!))
                                  : null,
                              child: profileListing?.sellerAvatarUrl != null && profileListing!.sellerAvatarUrl!.isNotEmpty
                                  ? null
                                  : Text(
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
                        _sellerUser?.storeName?.isNotEmpty == true
                            ? _sellerUser!.storeName!
                            : widget.sellerName,
                        textAlign: TextAlign.center,
                        style: AppTypography.h2(),
                      ),
                      if (_sellerUser?.storeDescription?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          _sellerUser!.storeDescription!,
                          textAlign: TextAlign.center,
                          style: AppTypography.body(color: AppColors.textSecondary),
                        ),
                      ],
                      if (_sellerUser?.hasPhysicalStore == true &&
                          _sellerUser?.storeAddress?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.mapPin,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _sellerUser!.storeAddress!,
                              style: AppTypography.caption(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Center(
                        child: RatingRow(
                          rating: rating,
                          reviewCount: reviewCount,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: isMe ? () {
                              if (_sellerUser != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FollowersScreen(userId: _sellerUser!.id),
                                  ),
                                );
                              }
                            } : null,
                            child: Text(
                              '$followerCount Followers',
                              style: AppTypography.body(color: AppColors.textSecondary).copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 16),
                            InkWell(
                              onTap: () {
                                if (_sellerUser != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FollowingScreen(userId: _sellerUser!.id),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                '$followingCount Following',
                                style: AppTypography.body(color: AppColors.textSecondary).copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ],
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
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          if (!isMe)
                            ElevatedButton(
                              onPressed: _toggleFollow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFollowing ? AppColors.surfaceMuted : AppColors.forestGreen,
                                foregroundColor: isFollowing ? AppColors.textPrimary : AppColors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: Text(isFollowing ? 'Following' : 'Follow'),
                            ),
                          OutlinedButton(
                            onPressed: () async {
                              final allowed = await ensureRegisteredAccount(context, reason: 'Sign in to message sellers.');
                              if (!context.mounted || !allowed) return;

                              MessageStoreScope.of(context).navigateToSellerChat(
                                context,
                                sellerName: widget.sellerName,
                                listing: profileListing,
                                client: ApiClientScope.of(context),
                                currentUserId: UserSessionScope.of(context).currentUser?.id,
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: const Text('Message seller'),
                          ),
                          if (profileListing != null)
                            OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ListingReviewsScreen(
                                      listing: profileListing,
                                    ),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: const Text('Reviews'),
                            ),
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
