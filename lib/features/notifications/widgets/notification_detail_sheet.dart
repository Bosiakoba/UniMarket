import 'package:flutter/material.dart';

import '../../../core/models/app_notification.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class NotificationDetailSheet extends StatelessWidget {
  const NotificationDetailSheet({super.key, required this.notification});

  final AppNotification notification;

  static Future<void> show(
    BuildContext context,
    AppNotification notification,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NotificationDetailSheet(notification: notification),
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
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(notification.title, style: AppTypography.h3()),
              ),
              const SizedBox(width: 12),
              Text(notification.timeLabel, style: AppTypography.caption()),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            notification.body,
            style: AppTypography.body(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 20),
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
