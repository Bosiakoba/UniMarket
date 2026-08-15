import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

import '../../constants/app_assets.dart';
import '../../theme/app_colors.dart';

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

  int get unreadCount => _threads.where((thread) => thread.unread).length;

  /// The thread currently open on screen. Incoming messages for this thread are
  /// treated as read (so the inbox badge doesn't light up while you're reading it).
  String? activeThreadId;

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
    String? sellerUserId,
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
      try {
        threadId = await client.openChat(listingId: listing.canonicalId);
      } catch (_) {
        // Fall back to local thread ID if API call fails.
      }
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
    String? sellerUserId,
    ListingItem? listing,
    ApiClient? client,
    String? currentUserId,
  }) async {
    final existing = listing == null ? _threadForSeller(sellerName) : null;
    final byListing = listing != null ? threadForListing(listing.canonicalId) : null;
    final existingThread = byListing ?? existing;

    if (existingThread != null) {
      if (listing != null) {
        existingThread.attachedListing = listing;
      }
      existingThread.unread = false;
      notifyListeners();

      if (client != null && isLiveSession(client)) {
        unawaited(refreshThreadMessages(
          threadId: existingThread.id,
          client: client,
          currentUserId: currentUserId,
        ).catchError((_) {}));
      }

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(threadId: existingThread.id),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(38),
      builder: (context) => const _NavigationLoadingOverlay(),
    );

    final MessageThread thread;
    try {
      thread = await openThreadForSeller(
        sellerName: sellerName,
        sellerUserId: sellerUserId,
        listing: listing,
        client: client,
      );
    } catch (_) {
      if (context.mounted) Navigator.of(context).pop();
      return;
    }

    if (client != null && isLiveSession(client)) {
      unawaited(refreshThreadMessages(
        threadId: thread.id,
        client: client,
        currentUserId: currentUserId,
      ).catchError((_) {}));
    }

    if (!context.mounted) return;
    Navigator.of(context).pop();

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(threadId: thread.id),
      ),
    );
  }

  Future<MessageThread> getOrFetchThread({
    required String threadId,
    required ApiClient client,
    required String userId,
  }) async {
    final existing = threadById(threadId);
    if (existing != null) return existing;

    if (isLiveSession(client)) {
      try {
        final rawChats = await client.fetchChats();
        final matchJson = rawChats.firstWhere((chat) => (chat['id'] as String) == threadId);
        final messagesRaw = await client.fetchChatMessages(threadId);
        final messages = messagesRaw
            .map((json) => ApiClient.messageFromJson(json, currentUserId: userId))
            .toList();

        final thread = MessageThread(
          id: threadId,
          sellerName: matchJson['otherPartyName'] as String? ?? matchJson['sellerName'] as String? ?? 'Seller',
          listingId: matchJson['listingId'] as String?,
          unread: matchJson['unread'] as bool? ?? false,
          isCurrentUserBuyer: matchJson['isBuyer'] as bool? ?? true,
          isOnline: matchJson['otherPartyIsOnline'] as bool? ?? false,
          lastSeenAt: matchJson['otherPartyLastSeenAt'] != null
              ? DateTime.tryParse(matchJson['otherPartyLastSeenAt'] as String)
              : null,
          otherPartyUserId: matchJson['otherPartyUserId'] as String?,
          messages: messages,
          listingTitle: matchJson['listingTitle'] as String?,
          listingImageUrl: matchJson['listingImageUrl'] as String?,
          listingPrice: (matchJson['listingPrice'] as num?)?.toDouble(),
        );

        _threads.add(thread);
        notifyListeners();
        return thread;
      } catch (_) {}
    }

    final fallback = MessageThread(
      id: threadId,
      sellerName: 'Chat Partner',
      messages: [],
    );
    _threads.add(fallback);
    notifyListeners();
    return fallback;
  }

  Future<void> refreshThreadMessages({
    required String threadId,
    required ApiClient client,
    String? currentUserId,
  }) async {
    if (!isLiveSession(client)) return;

    final thread = threadById(threadId);
    if (thread == null) return;

    try {
      final raw = await client.fetchChatMessages(threadId);
      final userId = currentUserId ?? '';
      final serverMessages = raw.map(
        (json) => ApiClient.messageFromJson(
          json,
          currentUserId: userId,
        ),
      ).toList();

      final optimistic = thread.messages
          .where((m) => m.sendStatus == ChatMessageSendStatus.sending ||
                        m.sendStatus == ChatMessageSendStatus.failed)
          .toList();

      final filteredOptimistic = optimistic.where((o) {
        final isAlreadyConfirmed = serverMessages.any((s) =>
            s.id == o.id ||
            s.text.trim() == o.text.trim() ||
            (o.listing != null && s.listing != null && s.listing!.id == o.listing!.id));
        return !isAlreadyConfirmed;
      }).toList();

      // Preserve locally edited messages — the edit API may not have synced yet.
      final localEdits = thread.messages
          .where((m) => m.isEdited)
          .fold<Map<String, ChatMessage>>({}, (map, m) {
            map[m.id] = m;
            return map;
          });

      thread.messages
        ..clear()
        ..addAll(serverMessages)
        ..addAll(filteredOptimistic);

      // Re-apply any local edits over the server versions
      if (localEdits.isNotEmpty) {
        for (var i = 0; i < thread.messages.length; i++) {
          final local = localEdits[thread.messages[i].id];
          if (local != null) {
            thread.messages[i] = local;
          }
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing messages: $e');
    }
  }

  Future<void> markRead(
    String threadId, {
    ApiClient? client,
  }) async {
    final thread = threadById(threadId);
    if (thread != null) {
      thread.unread = false;
    }
    if (client != null && isLiveSession(client)) {
      try {
        await client.markChatRead(chatId: threadId);
      } catch (_) {}
    }
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
      if (!thread.isCurrentUserBuyer) continue;
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

    final optimisticByThread = <String, List<ChatMessage>>{};
    for (final t in _threads) {
      final pending = t.messages.where((m) =>
          m.sendStatus == ChatMessageSendStatus.sending ||
          m.sendStatus == ChatMessageSendStatus.failed).toList();
      if (pending.isNotEmpty) {
        optimisticByThread[t.id] = pending;
      }
    }

    final cachedChats = client.getCached('/api/chats');
    if (cachedChats != null) {
      try {
        final List<dynamic> rawChats = jsonDecode(cachedChats);
        final List<MessageThread> localThreads = [];
        for (final chatJson in rawChats) {
          final chatId = chatJson['id'] as String;
          final cachedMessages = client.getCached('/api/chats/$chatId/messages');
          List<ChatMessage> messages = [];
          if (cachedMessages != null) {
            final List<dynamic> messagesRaw = jsonDecode(cachedMessages);
            messages = messagesRaw
                .map((json) => ApiClient.messageFromJson(json as Map<String, dynamic>, currentUserId: userId))
                .toList();
          }
          localThreads.add(
            MessageThread(
              id: chatId,
              sellerName: chatJson['otherPartyName'] as String? ?? chatJson['sellerName'] as String? ?? 'Seller',
              listingId: chatJson['listingId'] as String?,
              unread: chatJson['unread'] as bool? ?? false,
              isCurrentUserBuyer: chatJson['isBuyer'] as bool? ?? true,
              isOnline: chatJson['otherPartyIsOnline'] as bool? ?? false,
              lastSeenAt: chatJson['otherPartyLastSeenAt'] != null
                  ? DateTime.tryParse(chatJson['otherPartyLastSeenAt'] as String)
                  : null,
              otherPartyUserId: chatJson['otherPartyUserId'] as String?,
              messages: messages,
              listingTitle: chatJson['listingTitle'] as String?,
              listingImageUrl: chatJson['listingImageUrl'] as String?,
              listingPrice: (chatJson['listingPrice'] as num?)?.toDouble(),
            ),
          );
        }

        for (final fresh in localThreads) {
          final pending = optimisticByThread[fresh.id];
          if (pending != null) {
            final filteredPending = pending.where((o) {
              final isAlreadyConfirmed = fresh.messages.any((s) =>
                  s.id == o.id ||
                  s.text.trim() == o.text.trim() ||
                  (o.listing != null && s.listing != null && s.listing!.id == o.listing!.id));
              return !isAlreadyConfirmed;
            }).toList();
            fresh.messages.addAll(filteredPending);
          }
        }

        _threads
          ..clear()
          ..addAll(localThreads);
        notifyListeners();
      } catch (_) {}
    }

    try {
      final rawChats = await client.fetchChats();
      
      final threadFutures = rawChats.map((chatJson) async {
        final chatId = chatJson['id'] as String;
        final messagesRaw = await client.fetchChatMessages(chatId);
        final messages = messagesRaw
            .map((json) => ApiClient.messageFromJson(json, currentUserId: userId))
            .toList();

        return MessageThread(
          id: chatId,
          sellerName: chatJson['otherPartyName'] as String? ?? chatJson['sellerName'] as String? ?? 'Seller',
          listingId: chatJson['listingId'] as String?,
          unread: chatJson['unread'] as bool? ?? false,
          isCurrentUserBuyer: chatJson['isBuyer'] as bool? ?? true,
          isOnline: chatJson['otherPartyIsOnline'] as bool? ?? false,
          lastSeenAt: chatJson['otherPartyLastSeenAt'] != null
              ? DateTime.tryParse(chatJson['otherPartyLastSeenAt'] as String)
              : null,
          otherPartyUserId: chatJson['otherPartyUserId'] as String?,
          messages: messages,
          listingTitle: chatJson['listingTitle'] as String?,
          listingImageUrl: chatJson['listingImageUrl'] as String?,
          listingPrice: (chatJson['listingPrice'] as num?)?.toDouble(),
        );
      }).toList();

      final freshThreads = await Future.wait(threadFutures);

      for (final fresh in freshThreads) {
        final local = threadById(fresh.id);
        if (local != null && !local.unread) {
          fresh.unread = false;
        }
        final pending = optimisticByThread[fresh.id];
        if (pending != null) {
          final filteredPending = pending.where((o) {
            final isAlreadyConfirmed = fresh.messages.any((s) =>
                s.id == o.id ||
                s.text.trim() == o.text.trim() ||
                (o.listing != null && s.listing != null && s.listing!.id == o.listing!.id));
            return !isAlreadyConfirmed;
          }).toList();
          fresh.messages.addAll(filteredPending);
        }
      }

      _threads
        ..clear()
        ..addAll(freshThreads);
      notifyListeners();
    } catch (_) {
      // Keep local state if API unavailable.
    }
  }

  /// IDs of messages currently being sent – prevents duplicate sends.
  final Set<String> _pendingSendIds = {};

  /// Set of real-time message IDs already applied (dedup against FCM).
  final Set<String> _appliedRealTimeIds = {};

  /// Apply a message received in real-time (via SignalR or FCM data payload).
  /// This inserts or updates the message in the correct thread without a full refresh.
  void applyRealTimeMessage(
    Map<String, dynamic> data, {
    required String currentUserId,
  }) {
    final chatId = data['chatId'] as String?;
    final messageId = data['messageId'] as String?;
    final senderId = data['senderId'] as String? ?? '';
    final content = data['content'] as String? ?? '';
    final messageType = data['messageType'] as String? ?? 'text';

    if (chatId == null || messageId == null) return;

    // Dedup: if we already processed this message, skip it.
    if (_appliedRealTimeIds.contains(messageId)) return;
    _appliedRealTimeIds.add(messageId);
    pruneRealTimeIds();

    // Find or create the thread
    var thread = threadById(chatId);
    if (thread == null) {
      // Thread not yet loaded — schedule a background fetch.
      return;
    }

    final isMine = senderId == currentUserId &&
        (messageType == 'text' || messageType == 'listing_inquiry');

    ChatMessageKind kind = ChatMessageKind.text;
    if (messageType == 'sale_confirmation') {
      kind = ChatMessageKind.saleConfirmation;
    } else if (messageType == 'system_text') {
      kind = ChatMessageKind.systemText;
    }

    // Try to match and replace optimistic message in-place to avoid duplicates.
    // Keep the optimistic ID stable to prevent widget flicker — just update sendStatus.
    if (isMine) {
      final optIdx = thread.messages.indexWhere((m) =>
          (m.sendStatus == ChatMessageSendStatus.sending ||
           m.sendStatus == ChatMessageSendStatus.failed) &&
          (m.text.trim() == content.trim() ||
           (m.listing != null && messageType == 'listing_inquiry')));
      if (optIdx != -1) {
        thread.messages[optIdx] = thread.messages[optIdx].copyWith(
          sendStatus: ChatMessageSendStatus.sent,
        );
        _appliedRealTimeIds.add(messageId);
        notifyListeners();
        return;
      }
    }

    // Don't add if it's already in the list.
    final alreadyExists = thread.messages.any((m) => m.id == messageId);
    if (alreadyExists) return;

    thread.messages.add(
      ChatMessage(
        id: messageId,
        text: content,
        isMine: isMine,
        timeLabel: 'Just now',
        kind: kind,
      ),
    );

    // Mark unread for incoming messages from others — but not for the
    // conversation currently open on screen (it is being read right now).
    if (!isMine) {
      thread.unread = thread.id != activeThreadId;
    }

    notifyListeners();
  }

  /// Apply a presence update from the SignalR hub.
  /// Updates the matching thread's other party presence info.
  void applyPresenceUpdate({
    required String userId,
    required bool isOnline,
    DateTime? lastSeenAt,
  }) {
    var changed = false;
    for (final thread in _threads) {
      if (thread.otherPartyUserId == userId) {
        if (thread.isOnline != isOnline) {
          final idx = _threads.indexOf(thread);
          if (idx != -1) {
            final updated = MessageThread(
              id: thread.id,
              sellerName: thread.sellerName,
              messages: thread.messages,
              attachedListing: thread.attachedListing,
              unread: thread.unread,
              listingId: thread.listingId,
              buyerName: thread.buyerName,
              isCurrentUserBuyer: thread.isCurrentUserBuyer,
              isOnline: isOnline,
              lastSeenAt: isOnline ? null : lastSeenAt,
              otherPartyUserId: thread.otherPartyUserId,
              listingTitle: thread.listingTitle,
              listingImageUrl: thread.listingImageUrl,
              listingPrice: thread.listingPrice,
            );
            _threads[idx] = updated;
            changed = true;
          }
        }
      }
    }
    if (changed) notifyListeners();
  }

  /// Clean up old real-time message IDs to prevent unbounded growth.
  /// Called by ChatSignalRService periodically.
  void pruneRealTimeIds() {
    if (_appliedRealTimeIds.length > 1000) {
      _appliedRealTimeIds.clear();
    }
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

    // Generate a local optimistic ID.
    final optimisticId =
        'opt-${DateTime.now().millisecondsSinceEpoch}-${trimmed.hashCode}';

    // Guard against double-taps while a send is in flight.
    if (_pendingSendIds.contains(optimisticId)) return null;

    final displayText = trimmed.isEmpty ? 'Shared a listing' : trimmed;

    if (client != null &&
        isLiveSession(client) &&
        (trimmed.isNotEmpty || listing != null)) {
      // --- Optimistic insert ---
      _pendingSendIds.add(optimisticId);

      thread.messages.add(
        ChatMessage(
          id: optimisticId,
          text: displayText,
          isMine: true,
          timeLabel: 'Just now',
          listing: listing,
          sendStatus: ChatMessageSendStatus.sending,
        ),
      );
      notifyListeners();

      // --- Fire network request in the background ---
      try {
        final serverResponse = await client.sendChatMessage(
          chatId: threadId,
          content: trimmed.isEmpty ? 'Shared a listing inquiry' : trimmed,
          listingId: listing?.canonicalId,
        );

        // Update the optimistic message in-place:
        // Keep the optimistic ID stable for widget key consistency to prevent flicker.
        // Just mark as sent and track the server ID for SignalR dedup.
        final serverId = serverResponse?['id'] as String?;
        final idx = thread.messages.indexWhere((m) => m.id == optimisticId);
        if (idx != -1) {
          thread.messages[idx] = thread.messages[idx].copyWith(
            sendStatus: ChatMessageSendStatus.sent,
          );
          if (serverId != null && serverId.isNotEmpty) {
            // Track the mapping so SignalR delivery won't duplicate.
            _appliedRealTimeIds.add(serverId);
          }
        }
        notifyListeners();
      } catch (error) {
        // Mark the optimistic message as failed so the UI can show an indicator.
        final idx =
            thread.messages.indexWhere((m) => m.id == optimisticId);
        if (idx != -1) {
          thread.messages[idx] = thread.messages[idx].copyWith(
            sendStatus: ChatMessageSendStatus.failed,
          );
        }
        notifyListeners();
        return error.toString();
      } finally {
        _pendingSendIds.remove(optimisticId);
      }
      return null;
    }

    // Offline / demo mode – add locally only.
    thread.messages.add(
      ChatMessage(
        id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
        text: displayText,
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

  Future<String?> editMessage({
    required String threadId,
    required String messageId,
    required String newText,
    required ApiClient client,
  }) async {
    final thread = threadById(threadId);
    if (thread == null) return 'Conversation not found.';

    final msgIdx = thread.messages.indexWhere((m) => m.id == messageId);
    if (msgIdx == -1) return 'Message not found.';

    final oldText = thread.messages[msgIdx].text;
    final oldEdited = thread.messages[msgIdx].isEdited;

    // Optimistic edit
    thread.messages[msgIdx] = thread.messages[msgIdx].copyWith(
      text: newText,
      isEdited: true,
    );
    notifyListeners();

    try {
      await client.editChatMessage(
        chatId: threadId,
        messageId: messageId,
        content: newText,
      );
      return null;
    } catch (e) {
      // Revert on error
      final idx = thread.messages.indexWhere((m) => m.id == messageId);
      if (idx != -1) {
        thread.messages[idx] = thread.messages[idx].copyWith(
          text: oldText,
          isEdited: oldEdited,
        );
        notifyListeners();
      }
      return e.toString();
    }
  }

  Future<String?> deleteMessage({
    required String threadId,
    required String messageId,
    required bool forEveryone,
    required ApiClient client,
  }) async {
    final thread = threadById(threadId);
    if (thread == null) return 'Conversation not found.';

    final msgIdx = thread.messages.indexWhere((m) => m.id == messageId);
    if (msgIdx == -1) return 'Message not found.';

    final originalMessage = thread.messages[msgIdx];

    if (!forEveryone) {
      // Hide locally only
      thread.messages.removeAt(msgIdx);
      notifyListeners();
    } else {
      // Show deleted placeholder locally
      thread.messages[msgIdx] = originalMessage.copyWith(
        text: 'This message was deleted',
        isDeletedForAll: true,
      );
      notifyListeners();
    }

    try {
      await client.deleteChatMessage(
        chatId: threadId,
        messageId: messageId,
        forEveryone: forEveryone,
      );
      return null;
    } catch (e) {
      // Revert local state on error
      final idx = thread.messages.indexWhere((m) => m.id == messageId);
      if (!forEveryone) {
        if (idx == -1) {
          thread.messages.insert(msgIdx, originalMessage);
        }
      } else {
        if (idx != -1) {
          thread.messages[idx] = originalMessage;
        }
      }
      notifyListeners();
      return e.toString();
    }
  }

  void applyMessageEdited(String chatId, String messageId, String content) {
    final thread = threadById(chatId);
    if (thread == null) return;
    final idx = thread.messages.indexWhere((m) => m.id == messageId);
    if (idx != -1) {
      thread.messages[idx] = thread.messages[idx].copyWith(
        text: content,
        isEdited: true,
      );
      notifyListeners();
    }
  }

  void applyMessageDeleted(String chatId, String messageId) {
    final thread = threadById(chatId);
    if (thread == null) return;
    final idx = thread.messages.indexWhere((m) => m.id == messageId);
    if (idx != -1) {
      thread.messages[idx] = thread.messages[idx].copyWith(
        text: 'This message was deleted',
        isDeletedForAll: true,
      );
      notifyListeners();
    }
  }
}

class _NavigationLoadingOverlay extends StatelessWidget {
  const _NavigationLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Center(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 130,
              height: 130,
              color: AppColors.white.withAlpha(235),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    AppAssets.brandLogo,
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.forestGreen,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.forestGreen),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
