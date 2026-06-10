import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/brand_background.dart';
import '../../core/widgets/figma_asset.dart';
import '../../core/widgets/uni_button.dart';
import '../../routes/app_routes.dart';

class CategorySelectionScreen extends StatefulWidget {
  const CategorySelectionScreen({super.key});

  @override
  State<CategorySelectionScreen> createState() =>
      _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  static const _categories = [
    'Electronics & Gadget',
    'Fashion & Style',
    'Books & Stationery',
    'Food & Snacks',
    'Hostel & Room Essentials',
    'Transportation',
    'Services',
    'Tickets & Events',
    'Health & Beauty',
  ];

  final Set<String> _selected = {'Electronics & Gadget', 'Transportation'};

  void _toggle(String category) {
    setState(() {
      if (_selected.contains(category)) {
        _selected.remove(category);
      } else {
        _selected.add(category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.md),
                Text(
                  'What interests you?',
                  textAlign: TextAlign.center,
                  style: AppTypography.h1(color: AppColors.white),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'We\'ll personalize your campus feed',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(
                    color: AppColors.white.withValues(alpha: 0.88),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const Center(
                  child: FigmaAsset(
                    path: AppAssets.profileProgressMeterCategories,
                    width: 240,
                    height: 180,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: _categories.map((category) {
                        final isSelected = _selected.contains(category);
                        return GestureDetector(
                          onTap: () => _toggle(category),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.white
                                    : AppColors.white.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              category,
                              style: AppTypography.body(
                                color: isSelected
                                    ? AppColors.forestGreen
                                    : AppColors.white,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                UniButton(
                  label: 'Continue',
                  width: 240,
                  variant: UniButtonVariant.secondary,
                  onPressed: () => Navigator.of(context).pushReplacementNamed(
                    AppRoutes.home,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
