import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../api/api_client.dart';

class WishlistStore extends ChangeNotifier {
  final Set<String> _savedIds = {};

  bool contains(String listingId) => _savedIds.contains(listingId);

  List<String> get savedIds => List.unmodifiable(_savedIds);

  Future<void> syncFromApi(ApiClient client) async {
    final cachedWishlist = client.getCached('/api/wishlist');
    if (cachedWishlist != null) {
      try {
        final List<dynamic> list = jsonDecode(cachedWishlist);
        final items = list.map((item) => ListingMapper.fromJson(item as Map<String, dynamic>)).toList();
        _savedIds
          ..clear()
          ..addAll(items.map((item) => item.canonicalId));
        notifyListeners();
      } catch (_) {}
    }

    try {
      final items = await client.fetchWishlist();
      _savedIds
        ..clear()
        ..addAll(items.map((item) => item.canonicalId));
      notifyListeners();
    } catch (_) {
      // Keep local state if API unavailable.
    }
  }

  Future<void> toggle(String listingId, {ApiClient? client}) async {
    final id = listingId.contains('-dup')
        ? listingId.substring(0, listingId.length - 4)
        : listingId;

    if (_savedIds.contains(id)) {
      _savedIds.remove(id);
      notifyListeners();
      if (client != null) {
        try {
          await client.removeWishlist(id);
        } catch (_) {}
      }
      return;
    }

    _savedIds.add(id);
    notifyListeners();
    if (client != null) {
      try {
        await client.addWishlist(id);
      } catch (_) {}
    }
  }

  void clear() {
    _savedIds.clear();
    notifyListeners();
  }
}
