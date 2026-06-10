import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/models/category_field.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class DescriptionGuideCard extends StatelessWidget {
  const DescriptionGuideCard({
    super.key,
    required this.schema,
    this.title,
    this.items,
  });

  final CategoryPostingSchema schema;
  final String? title;
  final List<String>? items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                LucideIcons.lightbulb,
                size: 16,
                color: AppColors.forestGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title ?? 'What buyers expect in ${schema.category}',
                  style: AppTypography.bodyBold(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...(items ?? schema.descriptionChecklist).map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(height: 1.4)),
                  Expanded(
                    child: Text(item, style: AppTypography.caption()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
