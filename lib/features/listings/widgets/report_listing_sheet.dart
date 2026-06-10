import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/models/listing_item.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/uni_button.dart';

class ReportListingSheet extends StatefulWidget {
  const ReportListingSheet({super.key, required this.listing});

  final ListingItem listing;

  static Future<void> show(BuildContext context, ListingItem listing) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ReportListingSheet(listing: listing),
    );
  }

  @override
  State<ReportListingSheet> createState() => _ReportListingSheetState();
}

class _ReportListingSheetState extends State<ReportListingSheet> {
  static const _reasons = [
    'Fake or scam listing',
    'Misleading photos or description',
    'Prohibited item',
    'Seller impersonation',
    'Other',
  ];

  String? _selected;

  void _submit() {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a reason to report.')),
      );
      return;
    }

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Report submitted. Our campus team will review "${widget.listing.title}".',
        ),
      ),
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
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                LucideIcons.flag,
                color: AppColors.forestGreen,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Report listing', style: AppTypography.h3()),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Flag suspicious listings to keep the campus marketplace safe.',
            style: AppTypography.body(),
          ),
          const SizedBox(height: 16),
          ..._reasons.map((reason) {
            final selected = _selected == reason;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: selected
                    ? AppColors.forestGreen.withValues(alpha: 0.08)
                    : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => setState(() => _selected = reason),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.forestGreen
                            : AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(reason, style: AppTypography.body()),
                        ),
                        if (selected)
                          const Icon(
                            LucideIcons.check,
                            size: 16,
                            color: AppColors.forestGreen,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          UniButton(
            label: 'Submit report',
            variant: UniButtonVariant.green,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
