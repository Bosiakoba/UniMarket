import 'package:flutter/material.dart';

import '../data/stores/message_store.dart';

class MessageStoreScope extends InheritedNotifier<MessageStore> {
  const MessageStoreScope({
    super.key,
    required MessageStore store,
    required super.child,
  }) : super(notifier: store);

  static MessageStore of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<MessageStoreScope>();
    assert(scope != null, 'MessageStoreScope not found in widget tree');
    return scope!.notifier!;
  }
}
