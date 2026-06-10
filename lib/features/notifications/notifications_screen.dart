import 'package:flutter/material.dart';

import '../../core/models/app_notification.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'widgets/notification_detail_sheet.dart';
import 'widgets/notification_tile.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<AppNotification> _items;

  @override
  void initState() {
    super.initState();
    _items = const [
      AppNotification(
        id: 'n1',
        title: 'Verification approved',
        body: 'You can now post as a verified campus seller.',
        timeLabel: '2m',
        section: 'Today',
      ),
      AppNotification(
        id: 'n2',
        title: 'New listing near you',
        body: 'A calculus textbook was posted 0.2 km from Main Campus.',
        timeLabel: '1h',
        section: 'Today',
      ),
      AppNotification(
        id: 'n3',
        title: 'Jordan replied',
        body: 'Yes! Can meet at the library today.',
        timeLabel: '3h',
        section: 'Today',
      ),
      AppNotification(
        id: 'n4',
        title: 'Someone saved your listing',
        body: 'Your desk lamp was added to a wishlist.',
        timeLabel: 'Yesterday',
        section: 'Yesterday',
        isRead: true,
      ),
      AppNotification(
        id: 'n5',
        title: 'Campus market tips',
        body: 'Meet buyers in public campus spots and share clear photos.',
        timeLabel: 'Yesterday',
        section: 'Yesterday',
        isRead: true,
      ),
    ];
  }

  int get _unreadCount => _items.where((n) => !n.isRead).length;

  void _markAllRead() {
    setState(() {
      _items = _items.map((n) => n.copyWith(isRead: true)).toList();
    });
  }

  void _markRead(String id) {
    setState(() {
      _items = _items.map((n) {
        if (n.id == id) return n.copyWith(isRead: true);
        return n;
      }).toList();
    });
  }

  Future<void> _openNotification(AppNotification notification) async {
    _markRead(notification.id);
    await NotificationDetailSheet.show(context, notification);
  }

  List<String> get _sections {
    final seen = <String>[];
    for (final item in _items) {
      if (!seen.contains(item.section)) seen.add(item.section);
    }
    return seen;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Notifications', style: AppTypography.h3()),
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
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
          for (final section in _sections) ...[
            NotificationSectionHeader(label: section),
            ..._items.where((n) => n.section == section).map((notification) {
              final sectionItems =
                  _items.where((n) => n.section == section).toList();
              final isLast = sectionItems.last.id == notification.id;

              return Column(
                children: [
                  NotificationTile(
                    notification: notification,
                    onTap: () => _openNotification(notification),
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
  }
}
