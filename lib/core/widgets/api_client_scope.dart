import 'package:flutter/material.dart';

import '../api/api_client.dart';

class ApiClientScope extends InheritedWidget {
  const ApiClientScope({
    super.key,
    required this.client,
    required super.child,
  });

  final ApiClient client;

  static ApiClient of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ApiClientScope>();
    assert(scope != null, 'ApiClientScope not found in widget tree');
    return scope!.client;
  }

  @override
  bool updateShouldNotify(ApiClientScope oldWidget) =>
      oldWidget.client != client;
}
