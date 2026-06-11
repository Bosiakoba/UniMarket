import 'package:flutter/material.dart';

import '../../features/messages/chat_screen.dart';
import '../../features/sell/sell_entry.dart';
import '../../features/sell/verified_seller_screen.dart';
import '../models/app_notification.dart';
import '../models/listing_item.dart';
import '../navigation/listing_navigation.dart';
import '../widgets/message_store_scope.dart';
import '../widgets/seller_store_scope.dart';

abstract final class NotificationNavigation {
  static void open(BuildContext context, AppNotification notification) {
    final targetId = notification.targetId;
    if (targetId == null) return;

    switch (notification.type) {
      case NotificationType.listing:
      case NotificationType.wishlist:
        final sellerStore = SellerStoreScope.of(context);
        ListingItem? listing;
        for (final item in sellerStore.allListings) {
          if (item.canonicalId == targetId || item.id == targetId) {
            listing = item;
            break;
          }
        }
        if (listing != null) {
          ListingNavigation.openDetail(
            context,
            listing: listing,
            catalog: sellerStore,
          );
        }
      case NotificationType.message:
        final thread = MessageStoreScope.of(context).threadById(targetId);
        if (thread != null) {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ChatScreen(threadId: thread.id),
            ),
          );
        }
      case NotificationType.verification:
        if (targetId == 'verified') {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const VerifiedSellerScreen(),
            ),
          );
        } else {
          SellEntry.openVerifiedApplication(context);
        }
      case NotificationType.sellerApplication:
        SellEntry.openSellerApplication(context);
      case NotificationType.system:
        break;
    }
  }
}
