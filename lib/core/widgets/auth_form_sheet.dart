import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'brand_background.dart';

class AuthFormSheet extends StatelessWidget {
  const AuthFormSheet({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.forestGreen,
      child: Column(
        children: [
          SizedBox(
            height: 300,
            child: BrandBackground(
              child: SafeArea(
                bottom: false,
                child: Center(
                  child: Image.asset(
                    AppAssets.authLogo,
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                    cacheWidth: 360,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusSheet),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title, textAlign: TextAlign.center, style: AppTypography.h2()),
                    const SizedBox(height: AppSpacing.lg),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
