import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/chat_message.dart';
import '../../core/models/listing_item.dart';
import '../../core/models/message_thread.dart';
import '../../core/navigation/listing_navigation.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/seller_store_scope.dart';
import '../../core/theme/app_typography.dart';
import '../../core/data/stores/message_store.dart';
import '../../core/widgets/api_client_scope.dart';
import '../../core/widgets/message_store_scope.dart';
import '../../core/widgets/user_session_scope.dart';
import 'widgets/listing_attachment_card.dart';
import 'widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.threadId});

  final String threadId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  MessageStore? _store;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final store = MessageStoreScope.of(context);
      _store = store;
      store.activeThreadId = widget.threadId;
      final client = ApiClientScope.of(context);
      final userId = UserSessionScope.of(context).currentUser?.id;
      store.markRead(
        widget.threadId,
        client: ApiClientScope.of(context),
      );
      await store.refreshThreadMessages(
        threadId: widget.threadId,
        client: client,
        currentUserId: userId,
      );
      if (!mounted) return;
      final thread = store.threadById(widget.threadId);
      if (thread != null &&
          thread.attachedListing != null &&
          thread.messages.isEmpty) {
        _controller.text =
            'Hi! Is ${thread.attachedListing!.title} still available?';
      }
    });
  }

  @override
  void dispose() {
    if (_store?.activeThreadId == widget.threadId) {
      _store?.activeThreadId = null;
    }
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  bool _isSending = false;
  ChatMessage? _editingMessage;

  Future<void> _send() async {
    if (_isSending) return;

    final store = MessageStoreScope.of(context);
    final thread = store.threadById(widget.threadId);
    if (thread == null) return;

    final text = _controller.text;

    if (_editingMessage != null) {
      if (text.trim().isEmpty) return;
      final msgToEdit = _editingMessage!;
      _controller.clear();
      setState(() {
        _editingMessage = null;
      });

      _isSending = true;
      final error = await store.editMessage(
        threadId: widget.threadId,
        messageId: msgToEdit.id,
        newText: text,
        client: ApiClientScope.of(context),
      );
      _isSending = false;

      if (!mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
      return;
    }

    final listing = thread.attachedListing;
    if (text.trim().isEmpty && listing == null) return;

    // Clear input immediately for snappy feedback.
    _controller.clear();
    _scrollToBottom();

    _isSending = true;
    final error = await store.sendMessage(
      threadId: widget.threadId,
      text: text,
      listing: listing,
      client: ApiClientScope.of(context),
      currentUserId: UserSessionScope.of(context).currentUser?.id,
    );
    _isSending = false;

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final store = MessageStoreScope.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final thread = store.threadById(widget.threadId);

    if (thread == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat')),
        body: const Center(child: Text('Conversation not found')),
      );
    }

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final activeThread = store.threadById(widget.threadId)!;
        if (activeThread.unread) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              store.markRead(widget.threadId, client: ApiClientScope.of(context));
            }
          });
        }
        return _buildChat(context, activeThread, bottom);
      },
    );
  }

  Widget _buildChat(BuildContext context, MessageThread thread, double bottom) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(thread.sellerName, style: AppTypography.bodyBold()),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: thread.isOnline
                        ? const Color(0xFF34C759)
                        : AppColors.textTertiary,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  thread.isOnline
                      ? 'Online'
                      : _lastSeenText(thread.lastSeenAt),
                  style: AppTypography.caption(
                    color: thread.isOnline
                        ? const Color(0xFF34C759)
                        : AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.forestGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    thread.isCurrentUserBuyer ? 'Seller' : 'Buyer',
                    style: AppTypography.caption(
                      color: AppColors.forestGreen,
                    ).copyWith(fontWeight: FontWeight.w600, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _ProductContextBar(thread: thread),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: thread.messages.length,
              itemBuilder: (context, index) {
                final message = thread.messages[thread.messages.length - 1 - index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MessageBubble(
                    message: message,
                    threadId: widget.threadId,
                    viewerIsBuyer: thread.isCurrentUserBuyer,
                    onEditPressed: (msg) {
                      setState(() {
                        _editingMessage = msg;
                        _controller.text = msg.text;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          _Composer(
            controller: _controller,
            attachedListing: thread.attachedListing,
            onRemoveAttachment: () =>
                MessageStoreScope.of(context).clearAttachment(widget.threadId),
            onSend: _send,
            bottomPadding: bottom,
            editingMessage: _editingMessage,
            onCancelEdit: () {
              setState(() {
                _editingMessage = null;
                _controller.clear();
              });
            },
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.attachedListing,
    required this.onRemoveAttachment,
    required this.onSend,
    required this.bottomPadding,
    this.editingMessage,
    this.onCancelEdit,
  });

  final TextEditingController controller;
  final ListingItem? attachedListing;
  final VoidCallback onRemoveAttachment;
  final VoidCallback onSend;
  final double bottomPadding;
  final ChatMessage? editingMessage;
  final VoidCallback? onCancelEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 12),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (editingMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.edit3, size: 16, color: AppColors.forestGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Editing message',
                          style: AppTypography.caption(color: AppColors.forestGreen).copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          editingMessage!.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onCancelEdit,
                    icon: const Icon(LucideIcons.x, size: 16, color: AppColors.textTertiary),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (attachedListing != null && editingMessage == null) ...[
            ListingAttachmentCard(
              listing: attachedListing!,
              onRemove: onRemoveAttachment,
            ),
            const SizedBox(height: 10),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  style: AppTypography.body(),
                  decoration: InputDecoration(
                    hintText: editingMessage != null
                        ? 'Edit message...'
                        : (attachedListing != null
                            ? 'Ask about this listing...'
                            : 'Type a message...'),
                    hintStyle: AppTypography.body(
                      color: AppColors.textTertiary,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceMuted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.forestGreen,
                shape: const CircleBorder(),
                child: IconButton(
                  onPressed: onSend,
                  icon: Icon(
                    editingMessage != null ? LucideIcons.check : LucideIcons.send,
                    color: AppColors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Formats a [lastSeenAt] timestamp into a human-readable "last seen" string.
String _lastSeenText(DateTime? lastSeenAt) {
  if (lastSeenAt == null) return 'Offline';
  final now = DateTime.now();
  final diff = now.difference(lastSeenAt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return 'Last seen ${diff.inMinutes}m ago';
  if (diff.inHours < 24) return 'Last seen ${diff.inHours}h ago';
  if (diff.inDays < 7) return 'Last seen ${diff.inDays}d ago';
  return 'Last seen ${(diff.inDays / 7).floor()}w ago';
}

class _ProductContextBar extends StatelessWidget {
  const _ProductContextBar({
    required this.thread,
  });

  final MessageThread thread;

  @override
  Widget build(BuildContext context) {
    final title = thread.listingTitle ?? thread.attachedListing?.title;
    final price = thread.listingPrice ?? thread.attachedListing?.price;
    final imageUrl = thread.listingImageUrl ?? thread.attachedListing?.primaryPhotoSource;
    final listingId = thread.listingId ?? thread.attachedListing?.id;

    if (title == null || listingId == null) {
      return const SizedBox.shrink();
    }

    final formattedPrice = price != null ? '\$${price.toStringAsFixed(2)}' : '';

    return InkWell(
      onTap: () {
        final resolvedListing = thread.attachedListing ?? ListingItem(
          id: listingId,
          title: title,
          price: price ?? 0,
          imageAsset: imageUrl ?? '',
          photoUrls: imageUrl != null && imageUrl.isNotEmpty ? [imageUrl] : const [],
          sellerName: thread.sellerName,
          isVerified: false,
          distanceKm: 0,
          category: 'Listing',
        );

        final sellerStore = SellerStoreScope.of(context);
        ListingNavigation.openDetail(
          context,
          listing: resolvedListing,
          catalog: sellerStore,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: Row(
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  imageUrl,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 36,
                    height: 36,
                    color: AppColors.surfaceMuted,
                    child: const Icon(LucideIcons.image, size: 16, color: AppColors.textTertiary),
                  ),
                ),
              )
            else
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(LucideIcons.image, size: 16, color: AppColors.textTertiary),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyBold().copyWith(fontSize: 13),
                  ),
                  Text(
                    formattedPrice,
                    style: AppTypography.caption(color: AppColors.forestGreen).copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
