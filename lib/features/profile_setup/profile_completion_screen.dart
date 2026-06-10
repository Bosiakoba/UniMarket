import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/figma_asset.dart';
import '../../core/widgets/uni_button.dart';
import '../../core/widgets/uni_text_field.dart';
import '../../routes/app_routes.dart';
import '../../core/widgets/brand_background.dart';

class ProfileCompletionScreen extends StatelessWidget {
  const ProfileCompletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Complete your profile',
                        textAlign: TextAlign.center,
                        style: AppTypography.h1(color: AppColors.white),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Help buyers trust you on campus',
                        textAlign: TextAlign.center,
                        style: AppTypography.body(
                          color: AppColors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const FigmaAsset(
                        path: AppAssets.profileProgressMeter,
                        width: 240,
                        height: 240,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const UniTextField(hint: 'Full name', prefixIcon: Icons.person_outline),
                      const SizedBox(height: AppSpacing.md),
                      const UniTextField(hint: 'University', prefixIcon: Icons.school_outlined),
                      const SizedBox(height: AppSpacing.md),
                      const UniTextField(
                        hint: 'Phone number',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                child: UniButton(
                  label: 'Continue',
                  width: 240,
                  variant: UniButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pushReplacementNamed(
                    AppRoutes.categorySelection,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
