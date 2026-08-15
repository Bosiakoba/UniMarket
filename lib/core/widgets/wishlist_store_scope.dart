import 'package:flutter/material.dart';

import '../data/stores/wishlist_store.dart';

class WishlistStoreScope extends InheritedNotifier<WishlistStore> {
  const WishlistStoreScope({
    super.key,
    required WishlistStore store,
    required super.child,
  }) : super(notifier: store);

  static WishlistStore of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<WishlistStoreScope>();
    assert(scope != null, 'WishlistStoreScope not found in widget tree');
    return scope!.notifier!;
  }
}
