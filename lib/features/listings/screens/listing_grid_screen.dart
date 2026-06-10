import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/category_visuals.dart';
import '../../../core/data/services/home_feed_service.dart';
import '../../../core/models/home_feed_section.dart';
import '../../../core/models/listing_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/seller_store_scope.dart';
import '../widgets/listing_card.dart';

enum ListingGridMode { feedSection, category }

/// Reusable full-screen listing grid for home feed sections and categories.
class ListingGridScreen extends StatelessWidget {
  const ListingGridScreen.feedSection({
    super.key,
    required this.sectionId,
  })  : mode = ListingGridMode.feedSection,
        category = null;

  const ListingGridScreen.category({
    super.key,
    required this.category,
  })  : mode = ListingGridMode.category,
        sectionId = null;

  final ListingGridMode mode;
  final String? sectionId;
  final String? category;

  static void openFeedSection(BuildContext context, String sectionId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListingGridScreen.feedSection(sectionId: sectionId),
      ),
    );
  }

  static void openCategory(BuildContext context, String category) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListingGridScreen.category(category: category),
      ),
    );
  }

  List<ListingItem> _listings(List<ListingItem> catalog) {
    return switch (mode) {
      ListingGridMode.feedSection =>
        HomeFeedService.allListingsForSection(sectionId!, catalog),
      ListingGridMode.category =>
        catalog.where((l) => l.category == category).toList(),
    };
  }

  String _title(HomeFeedSection? section) {
    return switch (mode) {
      ListingGridMode.feedSection => section?.title ?? 'Listings',
      ListingGridMode.category => category!,
    };
  }

  String _countLabel(HomeFeedSection? section, int count) {
    if (count == 0) return 'No listings yet';
    if (mode == ListingGridMode.category) {
      return '$count listing${count == 1 ? '' : 's'} on campus';
    }
    if (section?.id == 'hot-deals') {
      return '$count deal${count == 1 ? '' : 's'} live on campus';
    }
    return '$count listing${count == 1 ? '' : 's'}';
  }

  String _emptyMessage(HomeFeedSection? section) {
    return switch (mode) {
      ListingGridMode.category =>
        'Nothing listed in this category yet.\nCheck back soon or post the first item.',
      ListingGridMode.feedSection => switch (section?.id) {
          'hot-deals' =>
            'Sellers can add a discount when posting or editing a listing.',
          'verified-sellers' =>
            'No verified seller listings on campus right now.',
          'near-you' => 'No nearby listings yet. Check back soon.',
          _ => 'Nothing in this section yet.',
        },
    };
  }

  @override
  Widget build(BuildContext context) {
    final sellerStore = SellerStoreScope.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return ListenableBuilder(
      listenable: sellerStore,
      builder: (context, _) {
        final catalog = sellerStore.allListings;
        final section = mode == ListingGridMode.feedSection
            ? HomeFeedService.sectionForId(sectionId!, catalog)
            : null;
        final listings = _listings(catalog);
        final title = _title(section);

        return Scaffold(
          backgroundColor: AppColors.white,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.h3(),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: mode == ListingGridMode.category
                      ? Row(
                          children: [
                            CategoryIcon(category: category!, size: 44),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category!,
                                    style: AppTypography.bodyBold(),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _countLabel(section, listings.length),
                                    style: AppTypography.caption(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (section?.subtitle != null &&
                                section!.subtitle!.isNotEmpty) ...[
                              Text(
                                section.subtitle!,
                                style: AppTypography.bodyBold(),
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              _countLabel(section, listings.length),
                              style: AppTypography.caption(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                ),
                Expanded(
                  child: listings.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              _emptyMessage(section),
                              textAlign: TextAlign.center,
                              style: AppTypography.body(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding:
                              EdgeInsets.fromLTRB(20, 0, 20, bottom + 20),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: ListingGrid.gridDelegate,
                          itemCount: listings.length,
                          itemBuilder: (context, index) =>
                              ListingCard(listing: listings[index]),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
