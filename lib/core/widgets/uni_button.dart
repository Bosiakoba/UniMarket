import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class UniButton extends StatelessWidget {
  const UniButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = UniButtonVariant.primary,
    this.width,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final UniButtonVariant variant;
  final double? width;
  final IconData? icon;
  final bool isLoading;

  Color get _labelColor => switch (variant) {
        UniButtonVariant.primary => AppColors.white,
        UniButtonVariant.green => AppColors.white,
        UniButtonVariant.secondary => AppColors.black,
        UniButtonVariant.outline => AppColors.black,
      };

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _labelColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: _labelColor),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label, style: AppTypography.button(color: _labelColor)),
            ],
          );

    final button = switch (variant) {
      UniButtonVariant.primary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.black,
            foregroundColor: AppColors.white,
            elevation: 0,
            minimumSize: Size(width ?? double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
          ),
          child: child,
        ),
      UniButtonVariant.secondary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.white,
            foregroundColor: AppColors.black,
            elevation: 0,
            minimumSize: Size(width ?? double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
          ),
          child: child,
        ),
      UniButtonVariant.outline => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.black,
            minimumSize: Size(width ?? double.infinity, 56),
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
          ),
          child: child,
        ),
      UniButtonVariant.green => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.forestGreen,
            foregroundColor: AppColors.white,
            elevation: 0,
            minimumSize: Size(width ?? double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
          ),
          child: child,
        ),
    };

    if (width != null) return Center(child: button);
    return button;
  }
}

enum UniButtonVariant { primary, secondary, outline, green }
