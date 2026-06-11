import 'package:flutter/foundation.dart';

import '../../models/app_notification.dart';

class NotificationStore extends ChangeNotifier {
  NotificationStore();

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
    _items.clear();
    notifyListeners();
  }
}
