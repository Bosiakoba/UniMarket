import 'package:flutter/material.dart';

import 'post_listing_screen.dart';

/// Dedicated edit flow for an existing seller listing.
class EditListingScreen extends StatelessWidget {
  const EditListingScreen({super.key, required this.listingId});

  final String listingId;

  static Future<void> open(BuildContext context, String listingId) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EditListingScreen(listingId: listingId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PostListingScreen(editingListingId: listingId);
  }
}
