import 'package:flutter/foundation.dart';

class WishlistStore extends ChangeNotifier {
  final Set<String> _savedIds = {};

  bool contains(String listingId) => _savedIds.contains(listingId);

  List<String> get savedIds => List.unmodifiable(_savedIds);

  void toggle(String listingId) {
    if (_savedIds.contains(listingId)) {
      _savedIds.remove(listingId);
    } else {
      _savedIds.add(listingId);
    }
    notifyListeners();
  }

  void clear() {
    _savedIds.clear();
    notifyListeners();
  }
}
