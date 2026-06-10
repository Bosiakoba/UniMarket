import 'package:flutter/material.dart';

import '../../core/data/mock/mock_listings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../features/listings/widgets/listing_card.dart';
import '../shell/main_shell.dart';
import '../shell/widgets/vault_feed_layout.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final saved = MockListings.items.take(4).toList();

    return VaultFeedLayout(
      headline: 'Saved\nlistings.',
      body: saved.isEmpty
          ? Center(
              child: Text(
                'Nothing saved yet',
                style: AppTypography.body(color: AppColors.textSecondary),
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
  }
}
