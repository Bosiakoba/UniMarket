import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'brand_background.dart';

class GreenFlowLayout extends StatelessWidget {
  const GreenFlowLayout({
    super.key,
    this.showBackButton = true,
    required this.illustration,
    required this.title,
    this.subtitle,
    this.bottom,
    required this.children,
  });

  final bool showBackButton;
  final Widget illustration;
  final String title;
  final String? subtitle;
  final Widget? bottom;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showBackButton)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      Center(child: illustration),
                      const SizedBox(height: AppSpacing.xl),
                      Text(title, textAlign: TextAlign.center, style: AppTypography.h1(color: AppColors.white)),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          style: AppTypography.body(
                            color: AppColors.white.withValues(alpha: 0.88),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      ...children,
                    ],
                  ),
                ),
              ),
              if (bottom != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                  child: bottom!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
