import 'package:flutter/material.dart';

import '../data/stores/app_preferences_store.dart';

class AppPreferencesScope extends InheritedNotifier<AppPreferencesStore> {
  const AppPreferencesScope({
    super.key,
    required AppPreferencesStore store,
    required super.child,
  }) : super(notifier: store);

  static AppPreferencesStore of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppPreferencesScope>();
    assert(scope != null, 'AppPreferencesScope not found in widget tree');
    return scope!.notifier!;
  }
}
