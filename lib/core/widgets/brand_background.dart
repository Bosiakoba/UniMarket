import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Rich green backdrop used on splash, onboarding, and auth headers.
class BrandBackground extends StatelessWidget {
  const BrandBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: _Blob(size: 220, color: AppColors.dustyRose.withValues(alpha: 0.18)),
          ),
          Positioned(
            bottom: 120,
            left: -100,
            child: _Blob(size: 280, color: AppColors.logoOrange.withValues(alpha: 0.12)),
          ),
          Positioned(
            top: 180,
            left: 40,
            child: _Blob(size: 100, color: AppColors.white.withValues(alpha: 0.06)),
          ),
          child,
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
