import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class SellerVerificationBenefitsScreen extends StatelessWidget {
  const SellerVerificationBenefitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Verification Benefits',
          style: AppTypography.h3(),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Image/Icon Section
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.forestGreen.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.badgeCheck,
                  size: 64,
                  color: AppColors.forestGreen,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Get Verified, Sell Faster',
                style: AppTypography.h2(),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Join trusted student sellers on UniMarket campus',
                textAlign: TextAlign.center,
                style: AppTypography.body(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 36),

            // Benefits List
            _buildBenefitRow(
              icon: LucideIcons.trendingUp,
              title: 'Priority in Search & Categories',
              description:
                  'Verified listings are strictly prioritized and displayed first in Hot Deals, Trending, and Near You categories.',
            ),
            const SizedBox(height: 24),
            _buildBenefitRow(
              icon: LucideIcons.shieldCheck,
              title: 'Verification Badge',
              description:
                  'A distinct checkmark badge on your profile and listings, signaling to buyers that your student status is verified.',
            ),
            const SizedBox(height: 24),
            _buildBenefitRow(
              icon: LucideIcons.messageSquare,
              title: 'Higher Conversion Rates',
              description:
                  'Verified sellers receive up to 3x more messages and close deals twice as fast due to increased peer-to-peer trust.',
            ),
            const SizedBox(height: 24),
            _buildBenefitRow(
              icon: LucideIcons.award,
              title: '100% Free for Students',
              description:
                  'Student verification is free. You only need to verify your university student email or upload your student ID.',
            ),
            const SizedBox(height: 48),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forestGreen,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  // Direct to application flow or close
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Got it',
                  style: AppTypography.bodyBold(color: AppColors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: AppColors.textPrimary,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyBold(),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTypography.caption(color: AppColors.textSecondary)
                    .copyWith(height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
