import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/constants/category_visuals.dart';
import '../../core/data/mock/mock_listings.dart';
import '../../core/models/listing_item.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/seller_store_scope.dart';
import '../listings/screens/listing_grid_screen.dart';
import '../listings/widgets/listing_card.dart';
import '../shell/main_shell.dart';
import '../shell/widgets/category_chip_row.dart';
import '../shell/widgets/vault_feed_layout.dart';
import '../shell/widgets/vault_search_bar.dart';

enum SearchSortMode {
  relevance('Best match'),
  verifiedFirst('Verified first'),
  nearest('Nearest'),
  priceLow('Price: low to high'),
  priceHigh('Price: high to low');

  const SearchSortMode(this.label);
  final String label;
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';
  String _selectedCategory = 'All';
  SearchSortMode _sort = SearchSortMode.relevance;

  static const _recentSearches = [
    'MacBook',
    'Textbooks',
    'Sneakers',
    'Design gigs',
  ];

  List<ListingItem> _results(List<ListingItem> source) {
    if (_query.trim().length < 2) return [];
    final q = _query.toLowerCase();
    final filtered = source.where((item) {
      final matchesCategory =
          _selectedCategory == 'All' || item.category == _selectedCategory;
      if (!matchesCategory) return false;
      return item.title.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q) ||
          item.sellerName.toLowerCase().contains(q) ||
          item.tags.any((tag) => tag.toLowerCase().contains(q)) ||
          item.attributes.values
              .any((value) => value.toLowerCase().contains(q));
    }).toList();

    filtered.sort((a, b) {
      switch (_sort) {
        case SearchSortMode.verifiedFirst:
          final verified = b.isVerified == a.isVerified
              ? 0
              : (b.isVerified ? 1 : -1);
          if (verified != 0) return verified;
          return a.distanceKm.compareTo(b.distanceKm);
        case SearchSortMode.nearest:
          return a.distanceKm.compareTo(b.distanceKm);
        case SearchSortMode.priceLow:
          return a.price.compareTo(b.price);
        case SearchSortMode.priceHigh:
          return b.price.compareTo(a.price);
        case SearchSortMode.relevance:
          final aVerified = a.isVerified ? 1 : 0;
          final bVerified = b.isVerified ? 1 : 0;
          if (bVerified != aVerified) return bVerified - aVerified;
          return a.distanceKm.compareTo(b.distanceKm);
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final sellerStore = SellerStoreScope.of(context);
    final hasQuery = _query.trim().length >= 2;

    return ListenableBuilder(
      listenable: sellerStore,
      builder: (context, _) {
        final results = _results(sellerStore.allListings);

        return VaultFeedLayout(
          showTopBar: false,
          headline: 'Search',
          stickyContent: Column(
            children: [
              VaultSearchBar(
                hint: 'Search by item, category, seller...',
                autofocus: false,
                onChanged: (value) => setState(() => _query = value),
              ),
              if (hasQuery) ...[
                CategoryChipRow(
                  categories: MockListings.categories,
                  selected: _selectedCategory,
                  onSelected: (cat) => setState(() => _selectedCategory = cat),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: PopupMenuButton<SearchSortMode>(
                    initialValue: _sort,
                    onSelected: (value) => setState(() => _sort = value),
                    itemBuilder: (context) => SearchSortMode.values
                        .map(
                          (mode) => PopupMenuItem(
                            value: mode,
                            child: Text(mode.label),
                          ),
                        )
                        .toList(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.arrowUpDown, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _sort.label,
                            style: AppTypography.caption(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          body: !hasQuery
              ? ListView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    floatingChromeBottomInset(context),
                  ),
                  children: [
                    Text('Recent searches', style: AppTypography.bodyBold()),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _recentSearches.map((term) {
                        return ActionChip(
                          label: Text(term, style: AppTypography.caption()),
                          backgroundColor: AppColors.surfaceMuted,
                          side: BorderSide.none,
                          onPressed: () => setState(() => _query = term),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                    Text('Browse by category', style: AppTypography.bodyBold()),
                    const SizedBox(height: 12),
                    ...MockListings.categories.where((c) => c != 'All').map(
                      (cat) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CategoryIcon(category: cat, size: 36),
                        title: Text(cat, style: AppTypography.body()),
                        trailing:
                            const Icon(LucideIcons.chevronRight, size: 16),
                        onTap: () =>
                            ListingGridScreen.openCategory(context, cat),
                      ),
                    ),
                  ],
                )
              : results.isEmpty
                  ? Center(
                      child: Text(
                        'No results for "$_query"',
                        style:
                            AppTypography.body(color: AppColors.textSecondary),
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
                      itemCount: results.length,
                      itemBuilder: (context, index) =>
                          ListingCard(listing: results[index]),
                    ),
        );
      },
    );
  }
}
