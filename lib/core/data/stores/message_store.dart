import 'package:flutter/material.dart';

import '../../../features/messages/chat_screen.dart';
import '../../models/chat_message.dart';
import '../../models/listing_item.dart';
import '../../models/message_thread.dart';
import '../mock/mock_listings.dart';

class MessageStore extends ChangeNotifier {
  MessageStore() {
    _threads.addAll([
      MessageThread(
        id: 'thread-jordan',
        sellerName: 'Jordan K.',
        unread: true,
        attachedListing: MockListings.items.first,
        messages: [
          const ChatMessage(
            id: 'm1',
            text: 'Is the MacBook still available?',
            isMine: true,
            timeLabel: '2m',
          ),
          const ChatMessage(
            id: 'm2',
            text: 'Yes! Can meet at the library today.',
            isMine: false,
            timeLabel: '1m',
          ),
        ],
      ),
      MessageThread(
        id: 'thread-campus-books',
        sellerName: 'Campus Books',
        messages: [
          const ChatMessage(
            id: 'm3',
            text: 'Thanks for your order!',
            isMine: false,
            timeLabel: '1h',
          ),
        ],
      ),
      MessageThread(
        id: 'thread-sam',
        sellerName: 'Sam R.',
        messages: [
          const ChatMessage(
            id: 'm4',
            text: 'Can we meet at the library?',
            isMine: false,
            timeLabel: 'Yesterday',
          ),
        ],
      ),
    ]);
  }

  final List<MessageThread> _threads = [];

  List<MessageThread> get threads =>
      List.unmodifiable(_threads.reversed.toList());

  MessageThread? threadById(String id) {
    for (final thread in _threads) {
      if (thread.id == id) return thread;
    }
    return null;
  }

  MessageThread? _threadForSeller(String sellerName) {
    for (final thread in _threads) {
      if (thread.sellerName == sellerName) return thread;
    }
    return null;
  }

  void clearAttachment(String threadId) {
    final thread = threadById(threadId);
    if (thread == null || thread.attachedListing == null) return;
    thread.attachedListing = null;
    notifyListeners();
  }

  MessageThread openThreadForSeller({
    required String sellerName,
    ListingItem? listing,
  }) {
    final existing = _threadForSeller(sellerName);

    if (existing != null) {
      if (listing != null) {
        existing.attachedListing = listing;
      }
      existing.unread = false;
      notifyListeners();
      return existing;
    }

    final thread = MessageThread(
      id: 'thread-${sellerName.hashCode}-${DateTime.now().millisecondsSinceEpoch}',
      sellerName: sellerName,
      attachedListing: listing,
      messages: [],
    );
    _threads.add(thread);
    notifyListeners();
    return thread;
  }

  void navigateToSellerChat(
    BuildContext context, {
    required String sellerName,
    ListingItem? listing,
  }) {
    final thread = openThreadForSeller(
      sellerName: sellerName,
      listing: listing,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(threadId: thread.id),
      ),
    );
  }

  void markRead(String threadId) {
    final thread = threadById(threadId);
    if (thread == null || !thread.unread) return;
    thread.unread = false;
    notifyListeners();
  }

  void sendMessage({
    required String threadId,
    required String text,
    ListingItem? listing,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty && listing == null) return;

    final thread = threadById(threadId);
    if (thread == null) return;

    if (listing != null) {
      thread.attachedListing = null;
    }

    thread.messages.add(
      ChatMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        text: trimmed.isEmpty ? 'Shared a listing' : trimmed,
        isMine: true,
        timeLabel: 'Just now',
        listing: listing,
      ),
    );
    notifyListeners();
  }
}
