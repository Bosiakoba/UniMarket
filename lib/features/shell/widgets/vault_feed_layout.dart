import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../routes/app_routes.dart';

class VaultFeedLayout extends StatelessWidget {
  const VaultFeedLayout({
    super.key,
    this.showTopBar = true,
    this.headline,
    this.subheadline,
    this.stickyContent,
    required this.body,
  });

  final bool showTopBar;
  final String? headline;
  final String? subheadline;
  final Widget? stickyContent;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showTopBar) const VaultTopBar(),
            if (headline != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline!,
                      style: AppTypography.h1().copyWith(
                        fontSize: 26,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subheadline != null) ...[
                      const SizedBox(height: 6),
                      Text(subheadline!, style: AppTypography.caption()),
                    ],
                  ],
                ),
              ),
            ?stickyContent,
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class VaultTopBar extends StatelessWidget {
  const VaultTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
      child: Row(
        children: [
          Image.asset(
            AppAssets.splashLogo,
            width: 40,
            height: 40,
            fit: BoxFit.contain,
            cacheWidth: 80,
          ),
          const Spacer(),
          _TopIcon(
            icon: LucideIcons.messageCircle,
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.messages),
          ),
          const SizedBox(width: 10),
          _TopIcon(
            icon: LucideIcons.bell,
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.notifications),
          ),
        ],
      ),
    );
  }
}

class _TopIcon extends StatelessWidget {
  const _TopIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceMuted,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
