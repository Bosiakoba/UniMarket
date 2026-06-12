import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/message_store_scope.dart';
import '../../../core/widgets/notification_store_scope.dart';
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
    final notificationStore = NotificationStoreScope.of(context);
    final messageStore = MessageStoreScope.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([notificationStore, messageStore]),
      builder: (context, _) {
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
                badgeCount: messageStore.unreadCount,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.messages),
              ),
              const SizedBox(width: 10),
              _TopIcon(
                icon: LucideIcons.bell,
                badgeCount: notificationStore.unreadCount,
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.notifications),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopIcon extends StatelessWidget {
  const _TopIcon({
    required this.icon,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final int badgeCount;

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
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(icon, size: 20, color: AppColors.textPrimary),
              if (badgeCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: _UnreadBadge(count: badgeCount),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';

    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.forestGreen,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.white, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
