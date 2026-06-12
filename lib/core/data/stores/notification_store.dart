import 'package:flutter/foundation.dart';

import '../../api/api_client.dart';
import '../../api/session_mode.dart';
import '../../models/app_notification.dart';

class NotificationStore extends ChangeNotifier {
  NotificationStore();

  final List<AppNotification> _items = [];

  List<AppNotification> get items => List.unmodifiable(_items);

  int get unreadCount => _items.where((n) => !n.isRead).length;

  Future<void> syncFromApi(ApiClient client) async {
    if (!isLiveSession(client)) return;

    try {
      final remote = await client.fetchNotifications();
      _items
        ..clear()
        ..addAll(remote);
      notifyListeners();
    } catch (_) {
      // Keep the local inbox if the network blips.
    }
  }

  Future<void> markReadRemote(String id, {ApiClient? client}) async {
    markRead(id);
    if (client == null || !isLiveSession(client)) return;
    try {
      await client.markNotificationRead(id);
    } catch (_) {
      // Local read state is still useful; the next sync will reconcile.
    }
  }

  void markRead(String id) {
    final index = _items.indexWhere((n) => n.id == id);
    if (index == -1 || _items[index].isRead) return;
    _items[index] = _items[index].copyWith(isRead: true);
    notifyListeners();
  }

  Future<void> markAllReadRemote({ApiClient? client}) async {
    markAllRead();
    if (client == null || !isLiveSession(client)) return;
    try {
      await client.markAllNotificationsRead();
    } catch (_) {
      // Local read state is still useful; the next sync will reconcile.
    }
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
