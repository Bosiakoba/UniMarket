import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/auth/auth_gate.dart';
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
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width > 600;

    Widget content = Column(
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
        // ignore: use_null_aware_elements
        if (stickyContent != null) stickyContent!,
        Expanded(child: body),
      ],
    );

    if (isDesktop) {
      content = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: content,
        ),
      );
    }

    return ColoredBox(
      color: AppColors.white,
      child: SafeArea(
        bottom: false,
        child: content,
      ),
    );
  }
}

Future<void> _openGatedRoute(
  BuildContext context,
  String route, {
  required String reason,
}) async {
  final allowed = await ensureRegisteredAccount(context, reason: reason);
  if (!allowed || !context.mounted) return;
  await Navigator.of(context).pushNamed(route);
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
        final isDesktop = MediaQuery.sizeOf(context).width > 600;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8), // Perfect horizontal alignment
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (!isDesktop) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      AppAssets.brandLogo,
                      width: 30,
                      height: 30,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.forestGreen,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'UniMarket',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.forestGreen,
                        letterSpacing: -0.6,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              _TopIcon(
                icon: LucideIcons.messageCircle,
                badgeCount: messageStore.unreadCount,
                onTap: () => _openGatedRoute(
                  context,
                  AppRoutes.messages,
                  reason: 'Sign in to view and reply to your messages.',
                ),
              ),
              const SizedBox(width: 8),
              _TopIcon(
                icon: LucideIcons.bell,
                badgeCount: notificationStore.unreadCount,
                onTap: () => _openGatedRoute(
                  context,
                  AppRoutes.notifications,
                  reason: 'Sign in to see campus notifications.',
                ),
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
        color: AppColors.dealRed,
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
