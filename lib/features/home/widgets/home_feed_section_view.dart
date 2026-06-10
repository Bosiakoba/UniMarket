import 'package:flutter/material.dart';

import '../../../core/models/home_feed_section.dart';
import '../../listings/screens/listing_grid_screen.dart';
import '../../listings/widgets/listing_card.dart';
import '../../listings/widgets/listing_compact_card.dart';
import '../../shell/widgets/vault_promo_banner.dart';
import 'home_category_tile.dart';
import 'home_section_header.dart';

class HomeFeedSectionView extends StatelessWidget {
  const HomeFeedSectionView({
    super.key,
    required this.section,
  });

  final HomeFeedSection section;

  @override
  Widget build(BuildContext context) {
    return switch (section.layout) {
      HomeSectionLayout.promo => const SliverToBoxAdapter(
          child: VaultPromoBanner(),
        ),
      HomeSectionLayout.categoriesHorizontal => SliverToBoxAdapter(
          child: _CategoriesHorizontalSection(section: section),
        ),
      HomeSectionLayout.categoriesGrid => SliverToBoxAdapter(
          child: _CategoriesGridSection(section: section),
        ),
      HomeSectionLayout.listingsHorizontal => SliverToBoxAdapter(
          child: _ListingsHorizontalSection(
            section: section,
            onSeeAll: () =>
                ListingGridScreen.openFeedSection(context, section.id),
          ),
        ),
      HomeSectionLayout.listingsGrid => SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: HomeSectionHeader(
                title: section.title,
                subtitle: section.subtitle,
                actionLabel: section.actionLabel,
                onAction: section.actionLabel != null
                    ? () => ListingGridScreen.openFeedSection(
                          context,
                          section.id,
                        )
                    : null,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: ListingGrid.sliverDelegate,
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      ListingCard(listing: section.listings[index]),
                  childCount: section.listings.length,
                ),
              ),
            ),
          ],
        ),
    };
  }
}

class _CategoriesHorizontalSection extends StatelessWidget {
  const _CategoriesHorizontalSection({required this.section});

  final HomeFeedSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionHeader(
          title: section.title,
          subtitle: section.subtitle,
        ),
        SizedBox(
          height: 118,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: section.categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final category = section.categories[index];
              return HomeCategoryTile(
                category: category,
                style: HomeCategoryTileStyle.horizontal,
                selected: false,
                onTap: () => ListingGridScreen.openCategory(context, category),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoriesGridSection extends StatelessWidget {
  const _CategoriesGridSection({required this.section});

  final HomeFeedSection section;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionHeader(
          title: section.title,
          subtitle: section.subtitle,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: section.categories.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.8,
            ),
            itemBuilder: (context, index) {
              final category = section.categories[index];
              return HomeCategoryTile(
                category: category,
                style: HomeCategoryTileStyle.grid,
                selected: false,
                onTap: () => ListingGridScreen.openCategory(context, category),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ListingsHorizontalSection extends StatelessWidget {
  const _ListingsHorizontalSection({
    required this.section,
    required this.onSeeAll,
  });

  final HomeFeedSection section;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final listings = section.listings;
    if (listings.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeSectionHeader(
          title: section.title,
          subtitle: section.subtitle,
          actionLabel: section.actionLabel,
          onAction: onSeeAll,
        ),
        SizedBox(
          height: ListingCompactCard.homeListingRowHeight,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: listings.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return ListingCompactCard(listing: listings[index]);
            },
          ),
        ),
      ],
    );
  }
}
