import 'package:flutter/material.dart';

import '../../../core/constants/category_visuals.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class CategoryChipRow extends StatelessWidget {
  const CategoryChipRow({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.iconFor,
  });

  final List<String> categories;
  final String selected;
  final ValueChanged<String> onSelected;
  final EdgeInsets padding;
  final IconData? Function(String category)? iconFor;

  static IconData iconForCategory(String cat) => CategoryVisuals.iconFor(cat);

  static Color colorForCategory(String cat) => CategoryVisuals.colorFor(cat);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          padding: padding,
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isSelected = cat == selected;
            return GestureDetector(
              onTap: () => onSelected(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.black : AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? AppColors.black : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CategoryIcon(
                      category: cat,
                      size: 30,
                      onDark: isSelected,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cat,
                      style: AppTypography.caption(
                        color: isSelected ? AppColors.white : AppColors.textPrimary,
                      ).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
