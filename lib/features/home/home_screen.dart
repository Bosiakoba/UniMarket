import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/api/session_mode.dart';
import '../../core/data/services/home_feed_service.dart';
import '../../core/models/app_user.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/api_client_scope.dart';
import '../../core/widgets/seller_store_scope.dart';
import '../../core/widgets/skeleton_loaders.dart';
import '../../core/widgets/user_session_scope.dart';
import '../../core/models/home_feed_section.dart';
import '../shell/main_shell.dart';
import '../shell/main_shell_scope.dart';
import '../shell/widgets/vault_feed_layout.dart';
import '../shell/widgets/vault_search_bar.dart';
import 'widgets/home_feed_section_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sellerStore = SellerStoreScope.of(context);

    return ListenableBuilder(
      listenable: sellerStore,
      builder: (context, _) {
        final client = ApiClientScope.of(context);
        final user = UserSessionScope.of(context).currentUser;
        final isLoadingFeed = sellerStore.isSyncingCatalog &&
            sellerStore.allListings.isEmpty &&
            isLiveSession(client);
        final sections = sellerStore.allListings.isNotEmpty
            ? HomeFeedService.buildFeed(sellerStore.allListings, user: user)
            : const <HomeFeedSection>[];

        return VaultFeedLayout(
          headline: 'Discover campus\ndeals near you.',
          stickyContent: HomeSearchHint(
            onTap: () => MainShellScope.of(context).goToTab(1),
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              final user = UserSessionScope.of(context).currentUser ??
                  const AppUser(
                    id: 'guest',
                    email: 'guest@unimarket.edu',
                    fullName: 'Guest User',
                    university: 'State University',
                    campus: 'Main Campus',
                  );
              await sellerStore.syncFromApi(
                ApiClientScope.of(context),
                user: user,
              );
            },
            child: isLoadingFeed
                ? const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: HomeFeedSkeleton(),
                  )
                : (sections.isEmpty
                    ? SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 100),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        AppColors.forestGreen.withValues(alpha: 0.18),
                                        AppColors.forestGreen.withValues(alpha: 0.04),
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    LucideIcons.store,
                                    size: 40,
                                    color: AppColors.forestGreen,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'No listings on campus yet',
                                  style: AppTypography.h2(),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Be the first to list an item or service! Pull down to refresh if you expect new postings.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.body(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          for (final section in sections)
                            HomeFeedSectionView(section: section),
                          SliverToBoxAdapter(
                            child: SizedBox(height: homeScrollBottomInset(context)),
                          ),
                        ],
                      )),
          ),
        );
      },
    );
  }
}
