import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class IdUploadCard extends StatelessWidget {
  const IdUploadCard({
    super.key,
    required this.uploaded,
    required this.onTap,
  });

  final bool uploaded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: uploaded
                ? AppColors.forestGreen.withValues(alpha: 0.08)
                : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: uploaded ? AppColors.forestGreen : AppColors.border,
              width: uploaded ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                uploaded ? LucideIcons.checkCircle2 : LucideIcons.upload,
                size: 32,
                color: uploaded
                    ? AppColors.forestGreen
                    : AppColors.textSecondary,
              ),
              const SizedBox(height: 10),
              Text(
                uploaded ? 'Student ID uploaded' : 'Upload student ID',
                style: AppTypography.bodyBold(),
              ),
              const SizedBox(height: 4),
              Text(
                uploaded
                    ? 'student_id.jpg · Tap to replace'
                    : 'Photo or scan of your campus student ID',
                textAlign: TextAlign.center,
                style: AppTypography.caption(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
