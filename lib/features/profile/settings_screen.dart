import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/api_client_scope.dart';
import '../../core/widgets/app_preferences_scope.dart';
import '../../core/widgets/message_store_scope.dart';
import '../../core/widgets/notification_store_scope.dart';
import '../../core/widgets/report_store_scope.dart';
import '../../core/widgets/review_store_scope.dart';
import '../../core/widgets/seller_store_scope.dart';
import '../../core/widgets/user_session_scope.dart';
import '../../core/widgets/wishlist_store_scope.dart';
import '../../routes/app_routes.dart';
import 'my_reports_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static void signOut(BuildContext context) {
    ApiClientScope.of(context).devUserId = null;
    UserSessionScope.of(context).signOut();
    SellerStoreScope.of(context).resetForSignOut();
    MessageStoreScope.of(context).clearAll();
    WishlistStoreScope.of(context).clear();
    ReviewStoreScope.of(context).clear();
    ReportStoreScope.of(context).clear();
    NotificationStoreScope.of(context).clear();
    AppPreferencesScope.of(context).reset();

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.signIn,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = UserSessionScope.of(context);
    final user = session.currentUser;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Settings', style: AppTypography.h3()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          if (user != null) ...[
            Text('Account', style: AppTypography.bodyBold()),
            const SizedBox(height: 8),
            _SettingsTile(
              icon: LucideIcons.mail,
              title: 'Campus email',
              subtitle: user.email,
            ),
            _SettingsTile(
              icon: LucideIcons.mapPin,
              title: 'Campus',
              subtitle: '${user.university} · ${user.campus}',
            ),
            const SizedBox(height: 20),
          ],
          Text('Marketplace', style: AppTypography.bodyBold()),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: LucideIcons.flag,
            title: 'My reports',
            subtitle: 'Listings you reported',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MyReportsScreen(),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Session', style: AppTypography.bodyBold()),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: LucideIcons.logOut,
            title: 'Sign out',
            subtitle: 'Clears local session on this device',
            onTap: () => signOut(context),
          ),
          const SizedBox(height: 24),
          Text(
            'Firebase Auth and Cloudflare will connect here later. '
            'Secrets stay off GitHub — use env vars on your home server.',
            style: AppTypography.caption(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textPrimary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.body()),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppTypography.caption()),
                  ],
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: AppColors.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}
