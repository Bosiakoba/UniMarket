import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_colors.dart';

class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    super.key,
    required this.rating,
    required this.onChanged,
    this.size = 28,
  });

  final int rating;
  final ValueChanged<int> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final star = index + 1;
        final filled = star <= rating;
        return IconButton(
          onPressed: () => onChanged(star),
          padding: const EdgeInsets.symmetric(horizontal: 2),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: Icon(
            LucideIcons.star,
            size: size,
            color: filled ? AppColors.verifiedGold : AppColors.border,
          ),
        );
      }),
    );
  }
}
