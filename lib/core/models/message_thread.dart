import 'chat_message.dart';
import 'listing_item.dart';

class MessageThread {
  MessageThread({
    required this.id,
    required this.sellerName,
    required this.messages,
    this.attachedListing,
    this.unread = false,
  });

  final String id;
  final String sellerName;
  final List<ChatMessage> messages;
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
    if (last.hasListing) {
      return 'Shared ${last.listing!.title}';
    }
    return last.text;
  }

  String get timeLabel =>
      messages.isEmpty ? 'Now' : messages.last.timeLabel;
}
