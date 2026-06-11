import 'package:flutter/material.dart';

import '../../core/models/listing_item.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/data/stores/seller_store.dart';
import '../../core/data/stores/wishlist_store.dart';
import '../../core/widgets/seller_store_scope.dart';
import '../../core/widgets/wishlist_store_scope.dart';
import '../listings/widgets/listing_card.dart';
import '../shell/main_shell.dart';
import '../shell/widgets/vault_feed_layout.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  List<ListingItem> _savedListings(
    WishlistStore wishlist,
    SellerStore sellerStore,
  ) {
    final ids = wishlist.savedIds.toSet();
    return sellerStore.allListings
        .where((item) => ids.contains(item.canonicalId) || ids.contains(item.id))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = WishlistStoreScope.of(context);
    final sellerStore = SellerStoreScope.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([wishlist, sellerStore]),
      builder: (context, _) {
        final saved = _savedListings(wishlist, sellerStore);

        return VaultFeedLayout(
          headline: 'Saved\nlistings.',
          body: saved.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Tap the heart on a listing to save it here.',
                      textAlign: TextAlign.center,
                      style:
                          AppTypography.body(color: AppColors.textSecondary),
                    ),
                  ),
                )
              : GridView.builder(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    floatingChromeBottomInset(context),
                  ),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: ListingGrid.gridDelegate,
                  itemCount: saved.length,
                  itemBuilder: (context, index) =>
                      ListingCard(listing: saved[index]),
                ),
        );
      },
    );
  }
}
