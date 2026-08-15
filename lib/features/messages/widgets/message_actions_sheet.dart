import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class MessageActionsSheet extends StatelessWidget {
  const MessageActionsSheet({
    super.key,
    required this.message,
    required this.onEdit,
    required this.onDeleteForMe,
    required this.onDeleteForEveryone,
  });

  final ChatMessage message;
  final VoidCallback onEdit;
  final VoidCallback onDeleteForMe;
  final VoidCallback onDeleteForEveryone;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    bool canDeleteForEveryone = false;

    if (message.isMine && !message.isDeletedForAll) {
      if (message.sentAt != null) {
        final difference = now.difference(message.sentAt!);
        if (difference.inHours < 1) {
          canDeleteForEveryone = true;
        }
      } else {
        // If sentAt is not available (like optimistic message or demo), assume yes
        canDeleteForEveryone = true;
      }
    }

    final isText = message.kind == ChatMessageKind.text;

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.paddingOf(context).bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (message.isMine && isText && !message.isDeletedForAll) ...[
            ListTile(
              leading: const Icon(LucideIcons.edit3, color: AppColors.textPrimary),
              title: Text('Edit Message', style: AppTypography.body()),
              onTap: () {
                Navigator.of(context).pop();
                onEdit();
              },
            ),
            const Divider(color: AppColors.border),
          ],
          ListTile(
            leading: const Icon(LucideIcons.trash2, color: Colors.redAccent),
            title: Text(
              'Delete for me',
              style: AppTypography.body(color: Colors.redAccent),
            ),
            onTap: () {
              Navigator.of(context).pop();
              onDeleteForMe();
            },
          ),
          if (canDeleteForEveryone) ...[
            const Divider(color: AppColors.border),
            ListTile(
              leading: const Icon(LucideIcons.shieldAlert, color: Colors.redAccent),
              title: Text(
                'Delete for everyone',
                style: AppTypography.body(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.of(context).pop();
                onDeleteForEveryone();
              },
            ),
          ],
        ],
      ),
    );
  }
}
