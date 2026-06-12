import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/listing_item.dart';
import '../../core/models/message_thread.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
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
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final store = MessageStoreScope.of(context);
      final client = ApiClientScope.of(context);
      final userId = UserSessionScope.of(context).currentUser?.id;
      store.markRead(widget.threadId);
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
      _startRefreshTimer();
    });
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final userId = UserSessionScope.of(context).currentUser?.id;
      MessageStoreScope.of(context).refreshThreadMessages(
        threadId: widget.threadId,
        client: ApiClientScope.of(context),
        currentUserId: userId,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final store = MessageStoreScope.of(context);
    final thread = store.threadById(widget.threadId);
    if (thread == null) return;

    final listing = thread.attachedListing;
    final text = _controller.text;

    if (text.trim().isEmpty && listing == null) return;

    final error = await store.sendMessage(
      threadId: widget.threadId,
      text: text,
      listing: listing,
      client: ApiClientScope.of(context),
      currentUserId: UserSessionScope.of(context).currentUser?.id,
    );
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    _controller.clear();
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
            Text('Campus seller', style: AppTypography.caption()),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: thread.messages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MessageBubble(
                    message: thread.messages[index],
                    threadId: widget.threadId,
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
  });

  final TextEditingController controller;
  final ListingItem? attachedListing;
  final VoidCallback onRemoveAttachment;
  final VoidCallback onSend;
  final double bottomPadding;

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
          if (attachedListing != null) ...[
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
                    hintText: attachedListing != null
                        ? 'Ask about this listing...'
                        : 'Type a message...',
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
                  icon: const Icon(
                    LucideIcons.send,
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
