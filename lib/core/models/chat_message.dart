import 'listing_item.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isMine,
    required this.timeLabel,
    this.listing,
  });

  final String id;
  final String text;
  final bool isMine;
  final String timeLabel;
  final ListingItem? listing;

  bool get hasListing => listing != null;
}
