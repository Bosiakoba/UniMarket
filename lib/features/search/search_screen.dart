import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/category_visuals.dart';
import '../../core/constants/market_categories.dart';
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

  List<String> _recentSearches = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('recent_searches') ?? [];
    setState(() {
      _recentSearches = saved;
    });
  }

  Future<void> _saveSearchTerm(String term) async {
    final clean = term.trim();
    if (clean.length < 2) return;

    _recentSearches.removeWhere((item) => item.toLowerCase() == clean.toLowerCase());
    _recentSearches.insert(0, clean);
    if (_recentSearches.length > 8) {
      _recentSearches = _recentSearches.sublist(0, 8);
    }
    setState(() {});

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_searches', _recentSearches);
  }

  Future<void> _clearRecentSearches() async {
    setState(() {
      _recentSearches = [];
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
  }

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
                onChanged: (value) {
                  _debounceTimer?.cancel();
                  _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      setState(() => _query = value);
                    }
                  });
                },
                onSubmitted: (value) => _saveSearchTerm(value),
              ),
              if (hasQuery) ...[
                CategoryChipRow(
                  categories: MarketCategories.feedCategories,
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
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 800;

                    if (isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left side: Vertical Browse Categories Sidebar
                          Container(
                            width: 280,
                            margin: const EdgeInsets.fromLTRB(20, 0, 12, 20),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: ListView(
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Text(
                                      'Browse by category',
                                      style: AppTypography.bodyBold().copyWith(fontSize: 16),
                                    ),
                                  ),
                                  const Divider(height: 1, color: AppColors.border),
                                  ...MarketCategories.listingCategories.map(
                                    (cat) => Material(
                                      color: Colors.transparent,
                                      child: ListTile(
                                        dense: true,
                                        leading: CategoryIcon(category: cat, size: 28),
                                        title: Text(
                                          cat,
                                          style: AppTypography.body().copyWith(fontSize: 14),
                                        ),
                                        trailing: const Icon(LucideIcons.chevronRight, size: 14),
                                        onTap: () =>
                                            ListingGridScreen.openCategory(context, cat),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Right side: Recent searches & Trending Deals
                          Expanded(
                            child: CustomScrollView(
                              physics: const BouncingScrollPhysics(),
                              slivers: [
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(12, 0, 20, 20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (_recentSearches.isNotEmpty) ...[
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Recent searches', style: AppTypography.bodyBold()),
                                              TextButton(
                                                onPressed: _clearRecentSearches,
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                ),
                                                child: Text(
                                                  'Clear all',
                                                  style: AppTypography.caption(color: AppColors.textSecondary),
                                                ),
                                              ),
                                            ],
                                          ),
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
                                        ],
                                        Text(
                                          'Trending campus deals',
                                          style: AppTypography.bodyBold().copyWith(fontSize: 18),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Popular listings on your campus feed right now',
                                          style: AppTypography.caption(color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(12, 0, 20, 40),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final innerWidth = constraints.maxWidth;
                                        final list = sellerStore.allListings;
                                        return MasonryGridView.count(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          crossAxisCount: ListingGrid.responsiveColumns(innerWidth),
                                          mainAxisSpacing: 14,
                                          crossAxisSpacing: 14,
                                          itemCount: list.length,
                                          itemBuilder: (context, index) => ListingCard(listing: list[index]),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        floatingChromeBottomInset(context),
                      ),
                      children: [
                        if (_recentSearches.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Recent searches', style: AppTypography.bodyBold()),
                              TextButton(
                                onPressed: _clearRecentSearches,
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Clear all',
                                  style: AppTypography.caption(color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
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
                        ],
                        Text('Browse by category', style: AppTypography.bodyBold()),
                        const SizedBox(height: 12),
                        ...MarketCategories.listingCategories.map(
                          (cat) => Material(
                            color: Colors.transparent,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CategoryIcon(category: cat, size: 36),
                              title: Text(cat, style: AppTypography.body()),
                              trailing: const Icon(LucideIcons.chevronRight, size: 16),
                              onTap: () =>
                                  ListingGridScreen.openCategory(context, cat),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                )
              : results.isEmpty
                  ? Center(
                      child: Text(
                        'No results for "$_query"',
                        style:
                            AppTypography.body(color: AppColors.textSecondary),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        return MasonryGridView.builder(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            0,
                            20,
                            floatingChromeBottomInset(context),
                          ),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: ListingGrid.responsiveColumns(width),
                          ),
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          itemCount: results.length,
                          itemBuilder: (context, index) => GestureDetector(
                            onTapDown: (_) => _saveSearchTerm(_query),
                            child: ListingCard(listing: results[index]),
                          ),
                        );
                      },
                    ),
        );
      },
    );
  }
}
