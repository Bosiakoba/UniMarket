import 'package:flutter/material.dart';

import '../../features/listings/screens/listing_detail_screen.dart';
import '../../features/listings/screens/listing_grid_screen.dart';
import '../data/stores/seller_store.dart';
import '../models/listing_item.dart';

/// Central entry points for listing-related navigation.
abstract final class ListingNavigation {
  static Future<void> openDetail(
    BuildContext context, {
    required ListingItem listing,
    required SellerStore catalog,
  }) {
    final resolved = listing.resolveAgainst(catalog.allListings);
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListingDetailScreen(listing: resolved),
      ),
    );
  }

  static void openFeedSection(BuildContext context, String sectionId) {
    ListingGridScreen.openFeedSection(context, sectionId);
  }

  static void openCategory(BuildContext context, String category) {
    ListingGridScreen.openCategory(context, category);
  }
}
