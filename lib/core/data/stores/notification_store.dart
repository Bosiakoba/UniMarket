import 'package:flutter/foundation.dart';

import '../../models/app_notification.dart';

class NotificationStore extends ChangeNotifier {
  NotificationStore() {
    _items.addAll(_seed);
  }

  static final _seed = [
    const AppNotification(
      id: 'n1',
      title: 'Verification approved',
      body: 'You can now post as a verified campus seller.',
      timeLabel: '2m',
      section: 'Today',
      type: NotificationType.verification,
      targetId: 'verified',
      actionLabel: 'View seller status',
    ),
    const AppNotification(
      id: 'n2',
      title: 'New listing near you',
      body: 'A calculus textbook was posted 0.2 km from Main Campus.',
      timeLabel: '1h',
      section: 'Today',
      type: NotificationType.listing,
      targetId: 'p1',
      actionLabel: 'View listing',
    ),
    const AppNotification(
      id: 'n3',
      title: 'Jordan replied',
      body: 'Yes! Can meet at the library today.',
      timeLabel: '3h',
      section: 'Today',
      type: NotificationType.message,
      targetId: 'thread-jordan',
      actionLabel: 'Open chat',
    ),
    const AppNotification(
      id: 'n4',
      title: 'Someone saved your listing',
      body: 'Your desk lamp was added to a wishlist.',
      timeLabel: 'Yesterday',
      section: 'Yesterday',
      isRead: true,
      type: NotificationType.wishlist,
      targetId: 'p5',
      actionLabel: 'View listing',
    ),
    const AppNotification(
      id: 'n5',
      title: 'Campus market tips',
      body: 'Meet buyers in public campus spots and share clear photos.',
      timeLabel: 'Yesterday',
      section: 'Yesterday',
      isRead: true,
      type: NotificationType.system,
    ),
  ];

  final List<AppNotification> _items = [];

  List<AppNotification> get items => List.unmodifiable(_items);

  int get unreadCount => _items.where((n) => !n.isRead).length;

  void markRead(String id) {
    final index = _items.indexWhere((n) => n.id == id);
    if (index == -1 || _items[index].isRead) return;
    _items[index] = _items[index].copyWith(isRead: true);
    notifyListeners();
  }

  void markAllRead() {
    var changed = false;
    for (var i = 0; i < _items.length; i++) {
      if (!_items[i].isRead) {
        _items[i] = _items[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void push(AppNotification notification) {
    _items.insert(0, notification);
    notifyListeners();
  }

  void clear() {
    _items
      ..clear()
      ..addAll(_seed);
    notifyListeners();
  }
}
