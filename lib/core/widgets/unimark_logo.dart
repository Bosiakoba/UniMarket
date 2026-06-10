import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class UniMarkLogo extends StatelessWidget {
  const UniMarkLogo({
    super.key,
    this.size = 120,
    this.showDot = true,
  });

  final double size;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final bagWidth = size * 0.75;
    final bagHeight = size * 0.85;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: bagWidth,
            height: bagHeight,
            decoration: BoxDecoration(
              gradient: AppColors.logoGradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(size * 0.12),
                topRight: Radius.circular(size * 0.12),
                bottomLeft: Radius.circular(size * 0.18),
                bottomRight: Radius.circular(size * 0.04),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -size * 0.06,
                  left: bagWidth * 0.28,
                  child: Container(
                    width: bagWidth * 0.44,
                    height: size * 0.1,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.logoOrange.withValues(alpha: 0.8),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(size * 0.05),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'UniMark',
                    style: GoogleFonts.poppins(
                      fontSize: size * 0.14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showDot)
            Positioned(
              right: size * 0.08,
              bottom: size * 0.12,
              child: Container(
                width: size * 0.14,
                height: size * 0.14,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.logoGradient,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
