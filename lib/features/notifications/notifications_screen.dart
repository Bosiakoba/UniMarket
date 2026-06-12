import 'package:flutter/material.dart';

import '../../core/models/app_notification.dart';
import '../../core/navigation/notification_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/api_client_scope.dart';
import '../../core/widgets/notification_store_scope.dart';
import 'widgets/notification_detail_sheet.dart';
import 'widgets/notification_tile.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationStoreScope.of(
        context,
      ).syncFromApi(ApiClientScope.of(context));
    });
  }

  Future<void> _openNotification(
    BuildContext context,
    AppNotification notification,
  ) async {
    final store = NotificationStoreScope.of(context);
    final client = ApiClientScope.of(context);
    await store.markReadRemote(notification.id, client: client);
    if (!context.mounted) return;

    await NotificationDetailSheet.show(context, notification);
    if (!context.mounted) return;

    if (notification.hasAction) {
      await NotificationNavigation.open(context, notification);
    }
  }

  List<String> _sections(List<AppNotification> items) {
    final seen = <String>[];
    for (final item in items) {
      if (!seen.contains(item.section)) seen.add(item.section);
    }
    return seen;
  }

  @override
  Widget build(BuildContext context) {
    final store = NotificationStoreScope.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final items = store.items;
        final unreadCount = store.unreadCount;
        final sections = _sections(items);

        return Scaffold(
          backgroundColor: AppColors.white,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text('Notifications', style: AppTypography.h3()),
            actions: [
              if (unreadCount > 0)
                TextButton(
                  onPressed: () => store.markAllReadRemote(
                    client: ApiClientScope.of(context),
                  ),
                  child: Text(
                    'Mark all read',
                    style: AppTypography.caption(color: AppColors.textPrimary),
                  ),
                ),
            ],
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 20),
            children: [
              for (final section in sections) ...[
                NotificationSectionHeader(label: section),
                ...items.where((n) => n.section == section).map((notification) {
                  final sectionItems = items
                      .where((n) => n.section == section)
                      .toList();
                  final isLast = sectionItems.last.id == notification.id;

                  return Column(
                    children: [
                      NotificationTile(
                        notification: notification,
                        onTap: () => _openNotification(context, notification),
                      ),
                      if (!isLast)
                        const Divider(height: 1, color: AppColors.border),
                    ],
                  );
                }),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }
}
