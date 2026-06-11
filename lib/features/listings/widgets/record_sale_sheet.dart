import 'package:flutter/material.dart';

import '../../../core/models/listing_availability.dart';
import '../../../core/models/listing_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/uni_button.dart';

class RecordSaleSheet extends StatefulWidget {
  const RecordSaleSheet({super.key, required this.listing});

  final ListingItem listing;

  static Future<int?> show(BuildContext context, ListingItem listing) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => RecordSaleSheet(listing: listing),
    );
  }

  @override
  State<RecordSaleSheet> createState() => _RecordSaleSheetState();
}

class _RecordSaleSheetState extends State<RecordSaleSheet> {
  late int _units;

  @override
  void initState() {
    super.initState();
    _units = 1;
  }

  int get _maxUnits {
    final listing = widget.listing;
    if (listing.availabilityType == ListingAvailabilityType.stock) {
      return listing.quantityAvailable ?? 1;
    }
    return 1;
  }

  String get _title =>
      ListingAvailabilityRules.recordSaleLabel(widget.listing.availabilityType);

  String get _subtitle {
    final listing = widget.listing;
    return switch (listing.availabilityType) {
      ListingAvailabilityType.ongoing =>
        'This records a completed job or booking. Your service stays listed.',
      ListingAvailabilityType.stock =>
        '${listing.quantityAvailable ?? 0} units currently available.',
      ListingAvailabilityType.unique =>
        'This is a one-of-a-kind item. Recording a sale removes it from the campus feed.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final listing = widget.listing;
    final showStepper =
        listing.availabilityType == ListingAvailabilityType.stock && _maxUnits > 1;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(_title, style: AppTypography.h3()),
          const SizedBox(height: 8),
          Text(
            listing.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(_subtitle, style: AppTypography.body()),
          if (showStepper) ...[
            const SizedBox(height: 20),
            Text('Units sold', style: AppTypography.bodyBold()),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: _units > 1 ? () => setState(() => _units--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_units', style: AppTypography.h2()),
                IconButton(
                  onPressed: _units < _maxUnits
                      ? () => setState(() => _units++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          UniButton(
            label: _title,
            variant: UniButtonVariant.green,
            onPressed: () => Navigator.of(context).pop(_units),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: AppTypography.bodyBold()),
          ),
        ],
      ),
    );
  }
}

class RestockSheet extends StatelessWidget {
  const RestockSheet({super.key, required this.listing});

  final ListingItem listing;

  static Future<int?> show(BuildContext context, ListingItem listing) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => RestockSheet(listing: listing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Restock listing', style: AppTypography.h3()),
          const SizedBox(height: 8),
          Text(
            'Add more units for ${listing.title}.',
            style: AppTypography.body(),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [5, 10, 20, 50].map((qty) {
              return ActionChip(
                label: Text('+$qty'),
                onPressed: () => Navigator.of(context).pop(qty),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: AppTypography.bodyBold()),
          ),
        ],
      ),
    );
  }
}
