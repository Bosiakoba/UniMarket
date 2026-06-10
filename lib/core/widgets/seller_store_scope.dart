import 'package:flutter/material.dart';

import '../data/stores/seller_store.dart';

class SellerStoreScope extends InheritedNotifier<SellerStore> {
  const SellerStoreScope({
    super.key,
    required SellerStore store,
    required super.child,
  }) : super(notifier: store);

  static SellerStore of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<SellerStoreScope>();
    assert(scope != null, 'SellerStoreScope not found in widget tree');
    return scope!.notifier!;
  }
}
