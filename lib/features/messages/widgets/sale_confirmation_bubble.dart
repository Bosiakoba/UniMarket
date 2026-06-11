import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/models/chat_message.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/uni_button.dart';

class SaleConfirmationBubble extends StatelessWidget {
  const SaleConfirmationBubble({
    super.key,
    required this.message,
    required this.onConfirm,
    required this.onDeny,
    this.isResponding = false,
  });

  final ChatMessage message;
  final VoidCallback onConfirm;
  final VoidCallback onDeny;
  final bool isResponding;

  @override
  Widget build(BuildContext context) {
    final responded = !message.canRespondToSale &&
        message.confirmationStatus != null &&
        message.confirmationStatus != 'pending';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.shieldCheck,
                size: 18,
                color: AppColors.forestGreen,
              ),
              const SizedBox(width: 8),
              Text('Purchase check', style: AppTypography.bodyBold()),
            ],
          ),
          const SizedBox(height: 8),
          Text(message.text, style: AppTypography.body()),
          const SizedBox(height: 12),
          if (responded)
            Text(
              message.confirmationStatus == 'confirmed'
                  ? 'You confirmed this purchase.'
                  : 'You said you did not buy this.',
              style: AppTypography.caption(color: AppColors.textSecondary),
            )
          else if (message.canRespondToSale)
            Row(
              children: [
                Expanded(
                  child: UniButton(
                    label: 'Yes, I bought it',
                    variant: UniButtonVariant.green,
                    isLoading: isResponding,
                    onPressed: isResponding ? null : onConfirm,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: UniButton(
                    label: 'No',
                    variant: UniButtonVariant.outline,
                    onPressed: isResponding ? null : onDeny,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
