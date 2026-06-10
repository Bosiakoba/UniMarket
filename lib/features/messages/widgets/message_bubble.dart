import 'package:flutter/material.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import 'listing_attachment_card.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
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
            if (message.text.isNotEmpty &&
                message.text != 'Shared a listing')
              Container(
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
            const SizedBox(height: 4),
            Text(message.timeLabel, style: AppTypography.caption()),
          ],
        ),
      ),
    );
  }
}
