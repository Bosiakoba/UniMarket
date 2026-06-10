import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/models/listing_item.dart';
import '../../../core/models/seller_listing_record.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/uni_button.dart';
import '../../sell/edit_listing_screen.dart';
import '../../seller/seller_profile_screen.dart';
import 'report_listing_sheet.dart';

enum _ListingAction {
  edit,
  markSold,
  markActive,
  delete,
  contact,
  call,
  viewSeller,
  report,
}

class ListingActionsSheet extends StatelessWidget {
  const ListingActionsSheet.owner({
    super.key,
    required this.listing,
    required this.record,
    required this.onMarkSold,
    required this.onMarkActive,
    required this.onDelete,
  })  : isOwner = true,
        phone = null,
        onContact = null;

  const ListingActionsSheet.buyer({
    super.key,
    required this.listing,
    required this.phone,
    required this.onContact,
  })  : isOwner = false,
        record = null,
        onMarkSold = null,
        onMarkActive = null,
        onDelete = null;

  final bool isOwner;
  final ListingItem listing;
  final SellerListingRecord? record;
  final String? phone;
  final VoidCallback? onContact;
  final VoidCallback? onMarkSold;
  final VoidCallback? onMarkActive;
  final Future<void> Function()? onDelete;

  static Future<void> showOwner(
    BuildContext context, {
    required ListingItem listing,
    required SellerListingRecord record,
    required VoidCallback onMarkSold,
    required VoidCallback onMarkActive,
    required Future<void> Function() onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ListingActionsSheet.owner(
        listing: listing,
        record: record,
        onMarkSold: onMarkSold,
        onMarkActive: onMarkActive,
        onDelete: onDelete,
      ),
    );
  }

  static Future<void> showBuyer(
    BuildContext context, {
    required ListingItem listing,
    required String phone,
    required VoidCallback onContact,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ListingActionsSheet.buyer(
        listing: listing,
        phone: phone,
        onContact: onContact,
      ),
    );
  }

  List<_ListingAction> get _actions {
    if (isOwner) {
      return [
        _ListingAction.edit,
        record!.isActive ? _ListingAction.markSold : _ListingAction.markActive,
        _ListingAction.delete,
      ];
    }
    return [
      _ListingAction.contact,
      _ListingAction.call,
      _ListingAction.viewSeller,
      _ListingAction.report,
    ];
  }

  String _label(_ListingAction action) {
    return switch (action) {
      _ListingAction.edit => 'Edit listing',
      _ListingAction.markSold => 'Mark as sold',
      _ListingAction.markActive => 'Mark as active',
      _ListingAction.delete => 'Delete listing',
      _ListingAction.contact => 'Message seller',
      _ListingAction.call => 'Call seller',
      _ListingAction.viewSeller => 'View seller profile',
      _ListingAction.report => 'Report listing',
    };
  }

  IconData _icon(_ListingAction action) {
    return switch (action) {
      _ListingAction.edit => LucideIcons.pencil,
      _ListingAction.markSold => LucideIcons.checkCircle2,
      _ListingAction.markActive => LucideIcons.circleDot,
      _ListingAction.delete => LucideIcons.trash2,
      _ListingAction.contact => LucideIcons.messageCircle,
      _ListingAction.call => LucideIcons.phone,
      _ListingAction.viewSeller => LucideIcons.user,
      _ListingAction.report => LucideIcons.flag,
    };
  }

  Future<void> _handleAction(BuildContext context, _ListingAction action) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final listingId = listing.id;
    final sellerName = listing.sellerName;
    final phoneNumber = phone;

    navigator.pop();

    switch (action) {
      case _ListingAction.edit:
        await navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => EditListingScreen(listingId: listingId),
          ),
        );
      case _ListingAction.markSold:
        onMarkSold?.call();
      case _ListingAction.markActive:
        onMarkActive?.call();
      case _ListingAction.delete:
        await onDelete?.call();
      case _ListingAction.contact:
        onContact?.call();
      case _ListingAction.call:
        messenger.showSnackBar(
          SnackBar(content: Text('Calling $phoneNumber')),
        );
      case _ListingAction.viewSeller:
        await navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => SellerProfileScreen(
              sellerName: sellerName,
              highlightListing: listing,
            ),
          ),
        );
      case _ListingAction.report:
        await ReportListingSheet.show(
          navigator.context,
          listing,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final actions = _actions;
    final regularActions =
        actions.where((a) => a != _ListingAction.delete).toList();
    final destructive =
        actions.where((a) => a == _ListingAction.delete).toList();

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
          Text(
            isOwner ? 'Manage listing' : 'Contact seller',
            style: AppTypography.h3(),
          ),
          const SizedBox(height: 6),
          Text(
            listing.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption(color: AppColors.textSecondary),
          ),
          if (isOwner && record != null) ...[
            const SizedBox(height: 4),
            Text(
              '${record!.statusLabel} · ${record!.views} views · ${record!.messages} inquiries',
              style: AppTypography.caption(),
            ),
          ],
          const SizedBox(height: 16),
          if (!isOwner) ...[
            UniButton(
              label: 'Message seller',
              variant: UniButtonVariant.green,
              onPressed: () => _handleAction(context, _ListingAction.contact),
            ),
            const SizedBox(height: 12),
          ],
          ...regularActions
              .where((a) => isOwner || a != _ListingAction.contact)
              .map(
            (action) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _ActionTile(
                  icon: _icon(action),
                  label: _label(action),
                  onTap: () => _handleAction(context, action),
                ),
              );
            },
          ),
          if (destructive.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...destructive.map(
              (action) => _ActionTile(
                icon: _icon(action),
                label: _label(action),
                destructive: true,
                onTap: () => _handleAction(context, action),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: AppTypography.bodyBold(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.red : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyBold(color: color),
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
