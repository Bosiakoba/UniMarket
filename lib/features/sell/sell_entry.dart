import 'package:flutter/material.dart';

import '../../core/widgets/seller_store_scope.dart';
import 'post_listing_screen.dart';
import 'seller_application_screen.dart';
import 'seller_application_status_screen.dart';
import 'verified_seller_screen.dart';

abstract final class SellEntry {
  static Future<void> openPostFlow(BuildContext context) async {
    final store = SellerStoreScope.of(context);

    if (store.sellerApplicationPending) {
      await SellerApplicationStatusScreen.open(
        context,
        continueToListing: true,
      );
      if (!context.mounted || !store.isSeller) return;
    } else if (!store.isSeller) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              const SellerApplicationScreen(continueToListing: true),
        ),
      );
      if (!context.mounted || !store.isSeller) return;
    }

    if (!context.mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const PostListingScreen()));
  }

  static Future<void> openSellerApplication(BuildContext context) async {
    final store = SellerStoreScope.of(context);

    if (store.sellerApplicationPending) {
      await SellerApplicationStatusScreen.open(context);
      return;
    }

    if (store.isSeller) {
      await SellerApplicationStatusScreen.open(context);
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SellerApplicationScreen()),
    );
  }

  static Future<void> openVerifiedApplication(BuildContext context) async {
    final store = SellerStoreScope.of(context);

    if (!store.isSeller) {
      await openSellerApplication(context);
      return;
    }

    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const VerifiedSellerScreen()),
    );
  }
}
