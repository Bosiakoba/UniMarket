import 'package:flutter/material.dart';

class MainShellScope extends InheritedWidget {
  const MainShellScope({
    super.key,
    required this.goToTab,
    required super.child,
  });

  final ValueChanged<int> goToTab;

  static MainShellScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MainShellScope>();
    assert(scope != null, 'MainShellScope not found');
    return scope!;
  }

  @override
  bool updateShouldNotify(MainShellScope oldWidget) =>
      oldWidget.goToTab != goToTab;
}
