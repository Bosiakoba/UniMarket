import 'package:flutter/material.dart';

import '../../core/api/session_mode.dart';
import '../../core/auth/auth_gate.dart';
import '../../core/widgets/api_client_scope.dart';
import '../../core/widgets/seller_store_scope.dart';
import '../../core/widgets/user_session_scope.dart';
import 'post_listing_screen.dart';
import 'seller_application_screen.dart';
import 'seller_application_status_screen.dart';
import 'verified_seller_screen.dart';
import '../seller/widgets/store_setup_sheet.dart';

abstract final class SellEntry {
  static Future<void> _refreshSellerStatus(BuildContext context) async {
    final session = UserSessionScope.of(context);
    final store = SellerStoreScope.of(context);
    final client = ApiClientScope.of(context);

    if (!isLiveSession(client) || session.currentUser == null) return;

    try {
      await store.refreshApplicationStatus(
        client: client,
        onUserUpdated: session.setCurrentUser,
      );
    } catch (_) {
      // Keep the last known local state if the network blips.
    }
  }

  static Future<void> openPostFlow(BuildContext context) async {
    final allowed = await ensureRegisteredAccount(
      context,
      reason: 'Sign in to post listings and reach buyers on your campus.',
    );
    if (!allowed || !context.mounted) return;

    // Show loading indicator while checking seller status
    if (context.mounted) {
      _showLoadingOverlay(context);
    }

    try {
      await _refreshSellerStatus(context);
    } finally {
      if (context.mounted) _dismissLoadingOverlay(context);
    }
    if (!context.mounted) return;

    final store = SellerStoreScope.of(context);

    if (store.sellerApplicationPending || store.sellerApplicationRejected) {
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
    final session = UserSessionScope.of(context);
    final user = session.currentUser;

    if (user != null && user.isVerified) {
      if (user.storeName == null || user.storeName!.trim().isEmpty) {
        // Show loading while setting up store
        if (context.mounted) _showLoadingOverlay(context);
        try {
          final didSetup = await StoreSetupSheet.show(context);
          if (didSetup != true) return; // cancelled
        } finally {
          if (context.mounted) _dismissLoadingOverlay(context);
        }
      }
    }

    if (!context.mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const PostListingScreen()));
  }

  /// Shows a centered loading overlay with a blur effect.
  static void _showLoadingOverlay(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(38),
      builder: (_) => PopScope(
        canPop: false,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  /// Dismisses the loading overlay if it's showing.
  static void _dismissLoadingOverlay(BuildContext context) {
    // Pop the loading dialog if it's the topmost route
    Navigator.of(context, rootNavigator: true).pop();
  }

  static Future<void> openSellerApplication(BuildContext context) async {
    final allowed = await ensureRegisteredAccount(
      context,
      reason: 'Sign in to apply as a campus seller.',
    );
    if (!allowed || !context.mounted) return;

    await _refreshSellerStatus(context);
    if (!context.mounted) return;

    final store = SellerStoreScope.of(context);

    if (store.sellerApplicationPending || store.sellerApplicationRejected) {
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
    final allowed = await ensureRegisteredAccount(
      context,
      reason: 'Sign in to apply for the verified seller badge.',
    );
    if (!allowed || !context.mounted) return;

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
