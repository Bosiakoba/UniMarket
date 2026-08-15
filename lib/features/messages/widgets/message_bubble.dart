import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/api_client_scope.dart';
import '../../../core/widgets/message_store_scope.dart';
import '../../../core/widgets/user_session_scope.dart';
import 'listing_attachment_card.dart';
import 'message_actions_sheet.dart';
import 'sale_confirmation_bubble.dart';

class MessageBubble extends StatefulWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.threadId,
    this.viewerIsBuyer = true,
    this.onEditPressed,
  });

  final ChatMessage message;
  final String threadId;
  final bool viewerIsBuyer;
  final void Function(ChatMessage)? onEditPressed;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isResponding = false;

  Future<void> _respond(bool confirmed) async {
    final saleId = widget.message.saleId;
    if (saleId == null || _isResponding) return;

    setState(() => _isResponding = true);
    final error = await MessageStoreScope.of(context).respondToSaleConfirmation(
      threadId: widget.threadId,
      saleId: saleId,
      confirmed: confirmed,
      client: ApiClientScope.of(context),
      currentUserId: UserSessionScope.of(context).currentUser?.id,
    );
    if (!mounted) return;
    setState(() => _isResponding = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  Future<void> _delete(bool forEveryone) async {
    final store = MessageStoreScope.of(context);
    final client = ApiClientScope.of(context);
    final error = await store.deleteMessage(
      threadId: widget.threadId,
      messageId: widget.message.id,
      forEveryone: forEveryone,
      client: client,
    );
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;

    if (message.isSaleConfirmation) {
      return SaleConfirmationBubble(
        message: message,
        viewerIsBuyer: widget.viewerIsBuyer,
        isResponding: _isResponding,
        onConfirm: () => _respond(true),
        onDeny: () => _respond(false),
      );
    }

    if (message.isSystemText) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.text,
            textAlign: TextAlign.center,
            style: AppTypography.caption(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final isMine = message.isMine;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Opacity(
          opacity: message.isSending ? 0.65 : 1.0,
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (message.listing != null) ...[
                ListingAttachmentCard(
                  listing: message.listing!,
                  compact: true,
                ),
                const SizedBox(height: 6),
              ],
              if (message.isDeletedForAll)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMine ? 16 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 16),
                    ),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.ban, size: 14, color: AppColors.textTertiary),
                      const SizedBox(width: 6),
                      Text(
                        'This message was deleted',
                        style: AppTypography.body(
                          color: AppColors.textTertiary,
                        ).copyWith(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                )
              else if (message.text.isNotEmpty &&
                  message.text != 'Shared a listing')
                GestureDetector(
                  onLongPress: () {
                    if (message.isDeletedForAll ||
                        message.isSystemText ||
                        message.isSaleConfirmation) {
                      return;
                    }
                    showModalBottomSheet<void>(
                      context: context,
                      backgroundColor: Colors.transparent,
                      builder: (context) => MessageActionsSheet(
                        message: message,
                        onEdit: () {
                          widget.onEditPressed?.call(message);
                        },
                        onDeleteForMe: () => _delete(false),
                        onDeleteForEveryone: () => _delete(true),
                      ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMine ? AppColors.forestGreen : AppColors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMine ? 16 : 4),
                        bottomRight: Radius.circular(isMine ? 4 : 16),
                      ),
                      border: isMine
                          ? null
                          : Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      message.text,
                      style: AppTypography.body(
                        color: isMine ? AppColors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              if (message.isFailed)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 14, color: Colors.redAccent),
                    const SizedBox(width: 4),
                    Text('Not sent',
                        style: AppTypography.caption(
                            color: Colors.redAccent)),
                  ],
                )
              else if (message.isSending)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('Sending…',
                        style: AppTypography.caption()),
                  ],
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.isEdited) ...[
                      Text(
                        'Edited',
                        style: AppTypography.caption(
                          color: AppColors.textTertiary,
                        ).copyWith(fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(width: 4),
                      Text('•',
                          style: AppTypography.caption(
                              color: AppColors.textTertiary)),
                      const SizedBox(width: 4),
                    ],
                    Text(message.timeLabel, style: AppTypography.caption()),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
