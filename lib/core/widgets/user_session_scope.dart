import 'package:flutter/material.dart';

import '../data/stores/user_session_store.dart';

class UserSessionScope extends InheritedNotifier<UserSessionStore> {
  const UserSessionScope({
    super.key,
    required UserSessionStore store,
    required super.child,
  }) : super(notifier: store);

  static UserSessionStore of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<UserSessionScope>();
    assert(scope != null, 'UserSessionScope not found in widget tree');
    return scope!.notifier!;
  }
}
