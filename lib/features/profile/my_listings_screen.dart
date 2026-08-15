import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/listing_item.dart';
import '../../core/models/seller_listing_record.dart';
import '../../core/models/listing_availability.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/listing_image.dart';
import '../../core/widgets/rating_row.dart';
import '../../core/widgets/seller_store_scope.dart';
import '../../core/widgets/uni_option_sheet.dart';
import '../../core/widgets/api_client_scope.dart';
import '../../core/widgets/user_session_scope.dart';
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
                        value: '${UserSessionScope.of(context).currentUser?.followingCount ?? 0}',
                        label: 'Following',
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

  void _showAppealDialog(BuildContext context, String listingId) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.white,
        title: Text('Submit Appeal', style: AppTypography.h3()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Explain why this listing should be reinstated:',
              style: AppTypography.body(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              style: AppTypography.body(),
              decoration: InputDecoration(
                hintText: 'Provide details or corrections made...',
                hintStyle: AppTypography.body(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.forestGreen, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: AppTypography.bodyBold(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final reason = controller.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter an appeal explanation.')),
                );
                return;
              }
              Navigator.of(dialogContext).pop();
              
              final store = SellerStoreScope.of(context);
              final client = ApiClientScope.of(context);
              
              final error = await store.submitAppeal(
                listingId: listingId,
                reason: reason,
                client: client,
              );
              
              if (context.mounted) {
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Appeal submitted successfully.')),
                  );
                }
              }
            },
            child: Text('Submit', style: AppTypography.bodyBold(color: AppColors.forestGreen)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listing = record.listing;
    final suspended = listing.lifecycleStatus == ListingLifecycleStatus.suspended;
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
                    child: ListingImage(
                      source: listing.primaryPhotoSource,
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
                        Text(
                          listing.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyBold(),
                        ),
                        const SizedBox(height: 6),
                        _StatusBadge(
                          label: suspended ? 'Suspended' : record.statusLabel,
                          sold: sold,
                          suspended: suspended,
                        ),
                        const SizedBox(height: 4),
                        ListingPriceText(
                          listing: listing,
                          style: AppTypography.price(),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          listing.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
              if (suspended) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: listing.appealComment != null
                        ? AppColors.white.withValues(alpha: 0.5)
                        : AppColors.dealRed.withValues(alpha: 0.05),
                    border: Border.all(
                      color: listing.appealComment != null
                          ? AppColors.border
                          : AppColors.dealRed.withValues(alpha: 0.2),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            listing.appealComment != null
                                ? LucideIcons.checkCircle
                                : LucideIcons.alertOctagon,
                            size: 16,
                            color: listing.appealComment != null
                                ? AppColors.textSecondary
                                : AppColors.dealRed,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              listing.appealComment != null
                                  ? 'Appeal under review'
                                  : 'Violated campus guidelines',
                              style: AppTypography.bodyBold().copyWith(
                                color: listing.appealComment != null
                                    ? AppColors.textPrimary
                                    : AppColors.dealRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        listing.appealComment != null
                            ? 'Your appeal: "${listing.appealComment}"'
                            : 'This listing is invisible to buyers. You can appeal to reinstate it.',
                        style: AppTypography.caption(color: AppColors.textSecondary),
                      ),
                      if (listing.appealComment == null) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _showAppealDialog(context, listing.id),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.dealRed,
                              side: const BorderSide(color: AppColors.dealRed),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text('Submit Appeal'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
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
  const _StatusBadge({
    required this.label,
    required this.sold,
    required this.suspended,
  });

  final String label;
  final bool sold;
  final bool suspended;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;
    if (suspended) {
      bgColor = AppColors.dealRed.withValues(alpha: 0.12);
      textColor = AppColors.dealRed;
    } else if (sold) {
      bgColor = AppColors.textTertiary.withValues(alpha: 0.15);
      textColor = AppColors.textSecondary;
    } else {
      bgColor = AppColors.forestGreen.withValues(alpha: 0.12);
      textColor = AppColors.forestGreen;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption().copyWith(
            color: textColor,
          ),
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
