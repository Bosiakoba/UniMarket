import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class InboxEmptyState extends StatelessWidget {
  const InboxEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.forestGreen.withValues(alpha: 0.18),
                    AppColors.forestGreen.withValues(alpha: 0.04),
                  ],
                ),
              ),
              child: const Icon(
                LucideIcons.messagesSquare,
                size: 40,
                color: AppColors.forestGreen,
              ),
            ),
            const SizedBox(height: 24),
            Text('No conversations yet', style: AppTypography.h2()),
            const SizedBox(height: 10),
            Text(
              'Tap Contact seller on any listing to start a chat. '
              'Your meetup plans and questions stay here.',
              textAlign: TextAlign.center,
              style: AppTypography.body(),
            ),
          ],
        ),
      ),
    );
  }
}
