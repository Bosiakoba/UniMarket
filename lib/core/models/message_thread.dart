import 'chat_message.dart';
import 'listing_item.dart';

class MessageThread {
  MessageThread({
    required this.id,
    required this.sellerName,
    required this.messages,
    this.attachedListing,
    this.unread = false,
    this.listingId,
    this.buyerName,
    this.isCurrentUserBuyer = true,
  });

  final String id;
  final String sellerName;
  final List<ChatMessage> messages;
  final String? listingId;
  final String? buyerName;
  final bool isCurrentUserBuyer;
  ListingItem? attachedListing;
  bool unread;

  String get sellerInitial =>
      sellerName.isNotEmpty ? sellerName[0].toUpperCase() : '?';

  String get preview {
    if (messages.isEmpty) {
      if (attachedListing != null) {
        return 'Interested in ${attachedListing!.title}';
      }
      return 'Start a conversation';
    }
    final last = messages.last;
    if (last.isSaleConfirmation) {
      if (last.canRespondToSale) return 'Confirm your purchase';
      if (last.confirmationStatus == 'pending') {
        return isCurrentUserBuyer
            ? 'Confirm your purchase'
            : 'Awaiting buyer confirmation';
      }
      if (last.confirmationStatus == 'confirmed') {
        return isCurrentUserBuyer
            ? 'You confirmed this purchase'
            : 'Buyer confirmed purchase';
      }
      if (last.confirmationStatus == 'denied') {
        return isCurrentUserBuyer
            ? 'You declined this purchase'
            : 'Buyer declined purchase';
      }
      return 'Purchase check';
    }
    if (last.isSystemText) {
      return last.text;
    }
    if (last.hasListing) {
      return 'Shared ${last.listing!.title}';
    }
    return last.text;
  }

  String get timeLabel =>
      messages.isEmpty ? 'Now' : messages.last.timeLabel;
}
