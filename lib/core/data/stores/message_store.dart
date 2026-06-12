import 'package:flutter/material.dart';

import '../../../features/messages/chat_screen.dart';
import '../../api/api_client.dart';
import '../../api/session_mode.dart';
import '../../models/chat_message.dart';
import '../../models/listing_availability.dart';
import '../../models/listing_item.dart';
import '../../models/message_thread.dart';
import '../mock/mock_listings.dart';

class MessageStore extends ChangeNotifier {
  MessageStore();

  final List<MessageThread> _threads = [];

  List<MessageThread> get threads =>
      List.unmodifiable(_threads.reversed.toList());

  MessageThread? threadById(String id) {
    for (final thread in _threads) {
      if (thread.id == id) return thread;
    }
    return null;
  }

  MessageThread? threadForListing(String listingId) {
    for (final thread in _threads) {
      if (thread.listingId == listingId) return thread;
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

  Future<MessageThread> openThreadForSeller({
    required String sellerName,
    ListingItem? listing,
    ApiClient? client,
  }) async {
    if (listing != null) {
      final byListing = threadForListing(listing.canonicalId);
      if (byListing != null) {
        byListing.attachedListing = listing;
        byListing.unread = false;
        notifyListeners();
        return byListing;
      }
    }

    final existing = listing == null ? _threadForSeller(sellerName) : null;
    if (existing != null) {
      if (listing != null) {
        existing.attachedListing = listing;
      }
      existing.unread = false;
      notifyListeners();
      return existing;
    }

    var threadId =
        'thread-${sellerName.hashCode}-${DateTime.now().millisecondsSinceEpoch}';
    if (client != null && isLiveSession(client) && listing != null) {
      threadId = await client.openChat(listingId: listing.canonicalId);
    }

    final thread = MessageThread(
      id: threadId,
      sellerName: sellerName,
      listingId: listing?.canonicalId,
      messages: [],
    )..attachedListing = listing;

    _threads.add(thread);
    notifyListeners();
    return thread;
  }

  Future<void> navigateToSellerChat(
    BuildContext context, {
    required String sellerName,
    ListingItem? listing,
    ApiClient? client,
    String? currentUserId,
  }) async {
    final thread = await openThreadForSeller(
      sellerName: sellerName,
      listing: listing,
      client: client,
    );
    if (client != null && isLiveSession(client)) {
      await refreshThreadMessages(
        threadId: thread.id,
        client: client,
        currentUserId: currentUserId,
      );
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(threadId: thread.id),
      ),
    );
  }

  Future<void> refreshThreadMessages({
    required String threadId,
    required ApiClient client,
    String? currentUserId,
  }) async {
    if (!isLiveSession(client)) return;

    final thread = threadById(threadId);
    if (thread == null) return;

    final raw = await client.fetchChatMessages(threadId);
    final userId = currentUserId ?? '';
    thread.messages
      ..clear()
      ..addAll(
        raw.map(
          (json) => ApiClient.messageFromJson(
            json,
            currentUserId: userId,
          ),
        ),
      );
    thread.unread = thread.messages.any(
      (m) => m.canRespondToSale,
    );
    notifyListeners();
  }

  Future<void> afterSaleRecorded({
    required ListingItem listing,
    required String saleId,
    required int units,
    ApiClient? client,
    String? currentUserId,
  }) async {
    if (client != null && isLiveSession(client)) {
      for (final thread in _threads) {
        if (thread.listingId == listing.canonicalId) {
          await refreshThreadMessages(
            threadId: thread.id,
            client: client,
            currentUserId: currentUserId,
          );
        }
      }
      return;
    }

    _injectLocalSaleConfirmation(
      listing: listing,
      saleId: saleId,
      units: units,
    );
  }

  void _injectLocalSaleConfirmation({
    required ListingItem listing,
    required String saleId,
    required int units,
  }) {
    final prompt = listing.availabilityType == ListingAvailabilityType.ongoing
        ? 'The seller recorded a completed job for "${listing.title}". Did you hire them for this?'
        : 'The seller recorded a sale for "${listing.title}". Did you buy this item?';

    final matching = _threads
        .where((thread) => thread.listingId == listing.canonicalId)
        .toList();

    if (matching.isEmpty) return;

    for (final thread in matching) {
      thread.messages.add(
        ChatMessage(
          id: 'sale-$saleId-${thread.id}',
          text: prompt,
          isMine: false,
          timeLabel: 'Just now',
          kind: ChatMessageKind.saleConfirmation,
          saleId: saleId,
          confirmationStatus: 'pending',
        ),
      );
      thread.unread = true;
    }
    notifyListeners();
  }

  Future<String?> respondToSaleConfirmation({
    required String threadId,
    required String saleId,
    required bool confirmed,
    ApiClient? client,
    String? currentUserId,
  }) async {
    final thread = threadById(threadId);
    if (thread == null) return 'Conversation not found.';

    if (client != null && isLiveSession(client)) {
      try {
        await client.respondToSale(saleId: saleId, confirmed: confirmed);
        await refreshThreadMessages(
          threadId: threadId,
          client: client,
          currentUserId: currentUserId,
        );
        return null;
      } catch (error) {
        return error.toString();
      }
    }

    for (var i = 0; i < thread.messages.length; i++) {
      final message = thread.messages[i];
      if (message.saleId == saleId && message.isSaleConfirmation) {
        thread.messages[i] = message.copyWith(
          confirmationStatus: confirmed ? 'confirmed' : 'denied',
        );
      }
    }
    thread.messages.add(
      ChatMessage(
        id: 'sale-reply-$saleId',
        text: confirmed
            ? 'Thanks — your purchase is confirmed.'
            : 'Thanks for letting us know.',
        isMine: false,
        timeLabel: 'Just now',
        kind: ChatMessageKind.systemText,
      ),
    );
    thread.unread = false;
    notifyListeners();
    return null;
  }

  Future<void> syncFromApi(ApiClient client, {required String userId}) async {
    if (!isLiveSession(client)) {
      if (_threads.isEmpty) resetToSeed();
      return;
    }

    try {
      final rawChats = await client.fetchChats();
      _threads.clear();

      for (final chatJson in rawChats) {
        final chatId = chatJson['id'] as String;
        final messagesRaw = await client.fetchChatMessages(chatId);
        final messages = messagesRaw
            .map(
              (json) => ApiClient.messageFromJson(
                json,
                currentUserId: userId,
              ),
            )
            .toList();

        _threads.add(
          MessageThread(
            id: chatId,
            sellerName: chatJson['otherPartyName'] as String? ??
                chatJson['sellerName'] as String? ??
                'Seller',
            listingId: chatJson['listingId'] as String?,
            unread: chatJson['unread'] as bool? ?? false,
            messages: messages,
          ),
        );
      }
      notifyListeners();
    } catch (_) {
      _threads.clear();
      notifyListeners();
    }
  }

  void markRead(String threadId) {
    final thread = threadById(threadId);
    if (thread == null || !thread.unread) return;
    thread.unread = false;
    notifyListeners();
  }

  Future<String?> sendMessage({
    required String threadId,
    required String text,
    ListingItem? listing,
    ApiClient? client,
    String? currentUserId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty && listing == null) return null;

    final thread = threadById(threadId);
    if (thread == null) return 'Conversation not found.';

    if (listing != null) {
      thread.attachedListing = null;
    }

    if (client != null && isLiveSession(client) && trimmed.isNotEmpty) {
      try {
        await client.sendChatMessage(chatId: threadId, content: trimmed);
        await refreshThreadMessages(
          threadId: threadId,
          client: client,
          currentUserId: currentUserId,
        );
        return null;
      } catch (error) {
        return error.toString();
      }
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
    return null;
  }

  void resetToSeed() {
    _threads
      ..clear()
      ..addAll([
        MessageThread(
          id: 'thread-jordan',
          sellerName: 'Jordan K.',
          listingId: '1',
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
    notifyListeners();
  }

  void clearAll() {
    _threads.clear();
    notifyListeners();
  }
}
