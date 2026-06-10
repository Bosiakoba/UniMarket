import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/models/listing_item.dart';
import '../../../core/models/message_thread.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class ThreadTile extends StatelessWidget {
  const ThreadTile({
    super.key,
    required this.thread,
    required this.onTap,
  });

  final MessageThread thread;
  final VoidCallback onTap;

  ListingItem? get _listingContext {
    if (thread.attachedListing != null) return thread.attachedListing;
    for (final message in thread.messages.reversed) {
      if (message.listing != null) return message.listing;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final listing = _listingContext;
    final unread = thread.unread;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: unread
                ? AppColors.forestGreen.withValues(alpha: 0.04)
                : AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: unread
                  ? AppColors.forestGreen.withValues(alpha: 0.22)
                  : AppColors.border,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Avatar(
                      initial: thread.sellerInitial,
                      unread: unread,
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
                                  thread.sellerName,
                                  style: AppTypography.bodyBold().copyWith(
                                    fontWeight: unread
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                thread.timeLabel,
                                style: AppTypography.caption(
                                  color: unread
                                      ? AppColors.forestGreen
                                      : AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            thread.preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.body(
                              color: unread
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ).copyWith(
                              fontWeight:
                                  unread ? FontWeight.w500 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (unread) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: const BoxDecoration(
                          color: AppColors.forestGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                if (listing != null) ...[
                  const SizedBox(height: 12),
                  _ListingContextRow(listing: listing),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial, required this.unread});

  final String initial;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: unread
            ? const LinearGradient(
                colors: [AppColors.forestGreen, Color(0xFF2E7D32)],
              )
            : null,
        border: unread
            ? null
            : Border.all(color: AppColors.border, width: 1.5),
      ),
      child: CircleAvatar(
        radius: 24,
        backgroundColor: AppColors.surfaceMuted,
        child: Text(
          initial,
          style: AppTypography.bodyBold(color: AppColors.forestGreen),
        ),
      ),
    );
  }
}

class _ListingContextRow extends StatelessWidget {
  const _ListingContextRow({required this.listing});

  final ListingItem listing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              listing.imageAsset,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(
                    color: AppColors.textPrimary,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'GHS ${listing.price.toStringAsFixed(0)} · ${listing.category}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(),
                ),
              ],
            ),
          ),
          const Icon(
            LucideIcons.chevronRight,
            size: 16,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
