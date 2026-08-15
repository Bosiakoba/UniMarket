import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';

/// Brand logo on a white disc, optionally inside a soft pulsing ring.
class BrandLogoMark extends StatelessWidget {
  const BrandLogoMark({
    super.key,
    this.size = 148,
    this.showOuterRing = true,
  });

  final double size;
  final bool showOuterRing;

  @override
  Widget build(BuildContext context) {
    final innerSize = size * 0.78;
    final padding = size * 0.15;

    final logo = Container(
      width: innerSize,
      height: innerSize,
      decoration: const BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
      ),
      padding: EdgeInsets.all(padding),
      child: Image.asset(
        AppAssets.brandLogo,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => Icon(
          Icons.storefront_rounded,
          color: AppColors.forestGreen,
          size: innerSize * 0.42,
        ),
      ),
    );

    if (!showOuterRing) return logo;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white.withValues(alpha: 0.14),
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.22),
          width: 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: logo,
    );
  }
}
