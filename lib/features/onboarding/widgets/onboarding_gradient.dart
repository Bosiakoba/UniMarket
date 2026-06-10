import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Vibrant mesh-style gradients — one mood per onboarding page.
class OnboardingGradient extends StatelessWidget {
  const OnboardingGradient({
    super.key,
    required this.pageIndex,
    required this.pageOffset,
    required this.child,
  });

  final int pageIndex;
  final double pageOffset;
  final Widget child;

  static const _gradients = [
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF062808),
        Color(0xFF093F0B),
        Color(0xFF1A5C22),
        Color(0xFF8B5E62),
      ],
      stops: [0.0, 0.35, 0.7, 1.0],
    ),
    LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF093F0B),
        Color(0xFF0F5A14),
        Color(0xFFCF9D9D),
        Color(0xFFFF8C42),
      ],
      stops: [0.0, 0.3, 0.72, 1.0],
    ),
    LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Color(0xFF0A4A12),
        Color(0xFF093F0B),
        Color(0xFF2D6B32),
        Color(0xFFE8B84A),
      ],
      stops: [0.0, 0.4, 0.75, 1.0],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final blend = pageOffset.clamp(-1.0, 1.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(gradient: _gradients[pageIndex]),
      child: Stack(
        children: [
          _GlowBlob(
            top: -60,
            right: -40,
            size: 240,
            color: AppColors.dustyRose.withValues(alpha: 0.28 + blend.abs() * 0.05),
          ),
          _GlowBlob(
            bottom: 180,
            left: -80,
            size: 300,
            color: AppColors.logoOrange.withValues(alpha: 0.18),
          ),
          _GlowBlob(
            top: 220,
            left: 60,
            size: 140,
            color: AppColors.white.withValues(alpha: 0.08),
          ),
          _GlowBlob(
            bottom: -40,
            right: 20,
            size: 200,
            color: AppColors.verifiedGold.withValues(alpha: 0.12),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    this.top,
    this.right,
    this.left,
    this.bottom,
    required this.size,
    required this.color,
  });

  final double? top;
  final double? right;
  final double? left;
  final double? bottom;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      left: left,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(color: color, blurRadius: size * 0.45, spreadRadius: size * 0.08),
          ],
        ),
      ),
    );
  }
}
