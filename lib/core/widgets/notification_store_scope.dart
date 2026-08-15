import 'package:flutter/material.dart';

import '../data/stores/notification_store.dart';

class NotificationStoreScope extends InheritedNotifier<NotificationStore> {
  const NotificationStoreScope({
    super.key,
    required NotificationStore store,
    required super.child,
  }) : super(notifier: store);

  static NotificationStore of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<NotificationStoreScope>();
    assert(scope != null, 'NotificationStoreScope not found in widget tree');
    return scope!.notifier!;
  }
}
