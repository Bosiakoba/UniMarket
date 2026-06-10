import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/listing_item.dart';
import '../../core/models/seller_listing_record.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/rating_row.dart';
import '../../core/widgets/seller_store_scope.dart';
import '../../core/widgets/uni_option_sheet.dart';
import '../../core/constants/category_visuals.dart';
import '../listings/screens/listing_detail_screen.dart';
import '../sell/edit_listing_screen.dart';
import '../listings/widgets/listing_price_text.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  _ListingFilter _filter = _ListingFilter.all;

  List<SellerListingRecord> _filtered(List<SellerListingRecord> records) {
    return switch (_filter) {
      _ListingFilter.all => records,
      _ListingFilter.active =>
        records.where((r) => r.isActive).toList(),
      _ListingFilter.sold =>
        records.where((r) => !r.isActive).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final store = SellerStoreScope.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        title: Text('My listings', style: AppTypography.h3()),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final records = store.listingRecords;
          final filtered = _filtered(records);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryStat(
                        value: '${store.activeCount}',
                        label: 'Active',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryStat(
                        value: '${store.soldCount}',
                        label: 'Sold',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryStat(
                        value: '${store.totalViews}',
                        label: 'Views',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryStat(
                        value: '${store.totalMessages}',
                        label: 'Inquiries',
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: PickerField(
                  label: 'Show',
                  value: _filter.label,
                  hint: 'Filter listings',
                  category: _filter.label,
                  onTap: () async {
                    final picked = await showUniOptionSheet<_ListingFilter>(
                      context: context,
                      title: 'Filter listings',
                      subtitle: 'View all, active, or sold posts.',
                      options: _ListingFilter.values,
                      labelFor: (filter) => filter.label,
                      selected: _filter,
                      leadingFor: (filter) => CategoryIcon(
                        category: filter.label,
                        size: 44,
                      ),
                    );
                    if (picked != null) setState(() => _filter = picked);
                  },
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No ${_filter.label.toLowerCase()} listings yet.',
                            style: AppTypography.body(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 20),
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final record = filtered[index];
                          return _ListingRecordCard(
                            record: record,
                            onTap: () => _openListing(context, record.listing),
                            onEdit: () => EditListingScreen.open(
                              context,
                              record.listing.id,
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _openListing(BuildContext context, ListingItem listing) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListingDetailScreen(listing: listing),
      ),
    );
  }
}

enum _ListingFilter {
  all('All'),
  active('Active'),
  sold('Sold');

  const _ListingFilter(this.label);
  final String label;
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
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

class _ListingRecordCard extends StatelessWidget {
  const _ListingRecordCard({
    required this.record,
    required this.onTap,
    required this.onEdit,
  });

  final SellerListingRecord record;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final listing = record.listing;
    final sold = !record.isActive;

    return Material(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      listing.imageAsset,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      cacheWidth: 160,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                listing.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodyBold(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusBadge(
                              label: record.statusLabel,
                              sold: sold,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ListingPriceText(
                          listing: listing,
                          style: AppTypography.price(),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          listing.category,
                          style: AppTypography.caption(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              RatingRow(
                rating: listing.rating,
                reviewCount: listing.reviewCount,
                compact: true,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _Metric(
                    icon: LucideIcons.eye,
                    label: '${record.views} views',
                  ),
                  const SizedBox(width: 16),
                  _Metric(
                    icon: LucideIcons.messageCircle,
                    label: '${record.messages} inquiries',
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(LucideIcons.pencil, size: 18),
                    tooltip: 'Edit listing',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                record.postedLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.sold});

  final String label;
  final bool sold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: sold
            ? AppColors.textTertiary.withValues(alpha: 0.15)
            : AppColors.forestGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTypography.caption(
          color: sold ? AppColors.textSecondary : AppColors.forestGreen,
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(label, style: AppTypography.caption()),
      ],
    );
  }
}
