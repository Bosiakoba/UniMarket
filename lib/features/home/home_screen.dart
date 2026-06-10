import 'package:flutter/material.dart';

import '../../core/data/services/home_feed_service.dart';
import '../../core/widgets/seller_store_scope.dart';
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
        final sections = HomeFeedService.buildFeed(sellerStore.allListings);

        return VaultFeedLayout(
          headline: 'Discover campus\ndeals near you.',
          stickyContent: HomeSearchHint(
            onTap: () => MainShellScope.of(context).goToTab(1),
          ),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              for (final section in sections)
                HomeFeedSectionView(section: section),
              SliverToBoxAdapter(
                child: SizedBox(height: homeScrollBottomInset(context)),
              ),
            ],
          ),
        );
      },
    );
  }
}
