import 'package:flutter/material.dart';

import '../data/stores/review_store.dart';

class ReviewStoreScope extends InheritedNotifier<ReviewStore> {
  const ReviewStoreScope({
    super.key,
    required ReviewStore store,
    required super.child,
  }) : super(notifier: store);

  static ReviewStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ReviewStoreScope>();
    assert(scope != null, 'ReviewStoreScope not found in widget tree');
    return scope!.notifier!;
  }
}
