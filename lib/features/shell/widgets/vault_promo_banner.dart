import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class VaultPromoBanner extends StatelessWidget {
  const VaultPromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      child: Container(
        height: 130,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verified sellers get\npriority in search',
                    style: AppTypography.bodyBold().copyWith(height: 1.35),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        'Learn more',
                        style: AppTypography.caption(
                          color: AppColors.textPrimary,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        LucideIcons.arrowRight,
                        size: 14,
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                AppAssets.ob1Collage6,
                width: 88,
                height: 94,
                fit: BoxFit.cover,
                cacheWidth: 200,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
