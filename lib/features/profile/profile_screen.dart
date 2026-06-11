import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/listing_item.dart';
import '../../core/navigation/listing_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/listing_image.dart';
import '../../core/widgets/seller_store_scope.dart';
import '../../core/widgets/user_session_scope.dart';
import '../../core/widgets/verified_badge.dart';
import '../../routes/app_routes.dart';
import '../sell/sell_entry.dart';
import 'edit_profile_screen.dart';
import 'settings_screen.dart';
import '../shell/main_shell.dart';
import 'my_listings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sellerStore = SellerStoreScope.of(context);
    final session = UserSessionScope.of(context);
    final user = session.currentUser;

    return ListenableBuilder(
      listenable: Listenable.merge([sellerStore, session]),
      builder: (context, _) {
        final isSeller = sellerStore.isSeller;
        final sellerPending = sellerStore.sellerApplicationPending;
        final isVerified = sellerStore.isVerified;
        final listingCount = sellerStore.activeCount;
        final displayName = user?.fullName ??
            sellerStore.sellerApplication?.fullName ??
            'Guest';
        final storeLabel = sellerStore.sellerApplication?.storeName;

        return ColoredBox(
          color: AppColors.white,
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
                  child: Row(
                    children: [
                      Text('Profile', style: AppTypography.h2()),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                        icon: const Icon(LucideIcons.settings, size: 22),
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: AppColors.surfaceMuted,
                            child: Text(
                              displayName[0],
                              style:
                                  AppTypography.h1(color: AppColors.forestGreen),
                            ),
                          ),
                          if (isVerified)
                            const Positioned(
                              bottom: 0,
                              right: -2,
                              child: VerifiedBadge(compact: true),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(displayName, style: AppTypography.h3()),
                      if (storeLabel != null) ...[
                        const SizedBox(height: 4),
                        Text(storeLabel, style: AppTypography.caption()),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        user == null
                            ? 'Sign in to sync your campus profile'
                            : '${user.university} · ${user.campus}',
                        style: AppTypography.caption(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              value: '$listingCount',
                              label: 'Listings',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              value: sellerStore.sellerRating.toStringAsFixed(1),
                              label: 'Rating',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              value: '${sellerStore.soldCount}',
                              label: 'Sold',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      20,
                      0,
                      20,
                      floatingChromeBottomInset(context),
                    ),
                    children: [
                      _SectionTitle('Seller'),
                      if (sellerPending)
                        _ProfileTile(
                          icon: LucideIcons.clock3,
                          title: 'Seller application',
                          subtitle: 'Campus review in progress',
                          onTap: () =>
                              SellEntry.openSellerApplication(context),
                        )
                      else if (!isSeller)
                        _ProfileTile(
                          icon: LucideIcons.store,
                          title: 'Apply to sell',
                          subtitle: 'Submit campus details to start selling',
                          onTap: () =>
                              SellEntry.openSellerApplication(context),
                        ),
                      _ProfileTile(
                        icon: LucideIcons.shieldCheck,
                        title: 'Verified badge',
                        subtitle: isVerified
                            ? 'Verified campus seller'
                            : sellerStore.verificationPending
                                ? 'Badge review in progress'
                                : sellerStore.canApplyForVerification
                                    ? 'You qualify — apply now'
                                    : 'Unlock after meeting seller criteria',
                        onTap: () =>
                            SellEntry.openVerifiedApplication(context),
                      ),
                      _ProfileTile(
                        icon: LucideIcons.plusCircle,
                        title: 'Post a listing',
                        subtitle: isSeller
                            ? 'Sell to students on campus'
                            : sellerPending
                                ? 'Waiting for seller approval'
                                : 'Apply to sell first',
                        onTap: () => SellEntry.openPostFlow(context),
                      ),
                      _ProfileTile(
                        icon: LucideIcons.package,
                        title: 'My listings',
                        subtitle:
                            '$listingCount active · ${sellerStore.soldCount} sold',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const MyListingsScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionTitle('Account'),
                      _ProfileTile(
                        icon: LucideIcons.user,
                        title: 'Edit profile',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        ),
                      ),
                      _ProfileTile(
                        icon: LucideIcons.messageCircle,
                        title: 'Messages',
                        onTap: () =>
                            Navigator.of(context).pushNamed(AppRoutes.messages),
                      ),
                      _ProfileTile(
                        icon: LucideIcons.bell,
                        title: 'Notifications',
                        onTap: () => Navigator.of(context)
                            .pushNamed(AppRoutes.notifications),
                      ),
                      const SizedBox(height: 16),
                      _SectionTitle('Recent listings'),
                      ...sellerStore.listingRecords
                          .where((r) => r.isActive)
                          .take(3)
                          .map(
                            (record) => _RecentListingRow(
                              listing: record.listing,
                              onTap: () =>
                                  _openListing(context, record.listing),
                            ),
                          ),
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton(
                          onPressed: () => SettingsScreen.signOut(context),
                          child: Text(
                            'Sign out',
                            style: AppTypography.body(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
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

  void _openListing(BuildContext context, ListingItem listing) {
    ListingNavigation.openDetail(
      context,
      listing: listing,
      catalog: SellerStoreScope.of(context),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(text, style: AppTypography.bodyBold()),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textPrimary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.body()),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppTypography.caption()),
                  ],
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentListingRow extends StatelessWidget {
  const _RecentListingRow({required this.listing, required this.onTap});

  final ListingItem listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ListingImage(
                source: listing.primaryPhotoSource,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                cacheWidth: 120,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
