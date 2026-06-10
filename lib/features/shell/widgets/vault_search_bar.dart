import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Minimal search field — no filter clutter.
class VaultSearchBar extends StatelessWidget {
  const VaultSearchBar({
    super.key,
    this.hint = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
  });

  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: TextField(
        readOnly: readOnly,
        autofocus: autofocus,
        onTap: onTap,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        style: AppTypography.body(),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.body(color: AppColors.textTertiary),
          prefixIcon: const Icon(
            LucideIcons.search,
            size: 18,
            color: AppColors.textTertiary,
          ),
          filled: true,
          fillColor: AppColors.surfaceMuted,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

/// Home-only tap target — opens Search tab, no input clutter.
class HomeSearchHint extends StatelessWidget {
  const HomeSearchHint({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(
                LucideIcons.search,
                size: 18,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 10),
              Text('Search campus listings', style: AppTypography.body()),
            ],
          ),
        ),
      ),
    );
  }
}
