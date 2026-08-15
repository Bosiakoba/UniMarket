import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../constants/app_assets.dart';
import '../theme/app_colors.dart';
import 'app_preferences_scope.dart';
import 'user_session_scope.dart';
import '../../app.dart';
import '../../features/sell/sell_entry.dart';
import '../../features/shell/main_shell.dart';
import '../../routes/app_routes.dart';

/// Tracks routing status globally to show/hide the sidebar correctly.
class AppRouteObserver extends NavigatorObserver {
  static final ValueNotifier<String?> currentRoute = ValueNotifier<String?>(null);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    currentRoute.value = route.settings.name;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    currentRoute.value = previousRoute?.settings.name;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    currentRoute.value = newRoute?.settings.name;
  }
}

/// Responsive viewport wrapper.
///
/// • Mobile (≤600px): renders content full-screen with no constraints.
/// • Desktop/Tablet (>600px): renders the content alongside a global left sidebar.
class MobileViewport extends StatelessWidget {
  const MobileViewport({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width > 600;

    if (!isDesktop) return child;

    final session = UserSessionScope.of(context);
    final preferences = AppPreferencesScope.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([session, preferences]),
      builder: (context, _) {
        final isLoggedIn = session.isLoggedIn;
        final onboardingComplete = preferences.onboardingComplete;

        // Only render the sidebar layout if logged in and onboarding is finished
        if (!isLoggedIn || !onboardingComplete) return child;

        return ValueListenableBuilder<String?>(
          valueListenable: AppRouteObserver.currentRoute,
          builder: (context, currentRouteName, _) {
            // Suppress the sidebar on full-screen introductory/onboarding/auth screens
            final hideSidebar = currentRouteName == AppRoutes.splash ||
                currentRouteName == AppRoutes.onboarding ||
                currentRouteName == AppRoutes.signIn ||
                currentRouteName == AppRoutes.signUp ||
                currentRouteName == AppRoutes.forgotPassword ||
                currentRouteName == AppRoutes.verification ||
                currentRouteName == AppRoutes.profileCompletion ||
                currentRouteName == AppRoutes.categorySelection;

            if (hideSidebar) return child;

            return Scaffold(
              backgroundColor: AppColors.white,
              body: Row(
                children: [
                  _GlobalSidebarNavBar(
                    onPost: () => SellEntry.openPostFlow(
                      UniMarketApp.navigatorKey.currentContext ?? context,
                    ),
                  ),
                  Expanded(
                    child: child,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _GlobalSidebarNavBar extends StatelessWidget {
  const _GlobalSidebarNavBar({required this.onPost});

  final VoidCallback onPost;

  void _onSidebarItemTapped(BuildContext context, int index) {
    // 1. Pop all routes until we reach the main home route using global navigatorKey
    UniMarketApp.navigatorKey.currentState?.popUntil(
      (route) => route.isFirst || route.settings.name == AppRoutes.home,
    );
    
    // 2. Set the tab in the MainShell
    MainShell.activeTab.value = index;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          right: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo & Brand Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Row(
              children: [
                Image.asset(
                  AppAssets.brandLogo,
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.storefront_rounded,
                    color: AppColors.forestGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'UniMarket',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.forestGreen,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
          ),

          // Nav Items
          Expanded(
            child: ValueListenableBuilder<String?>(
              valueListenable: AppRouteObserver.currentRoute,
              builder: (context, currentRouteName, child) {
                return ListenableBuilder(
                  listenable: MainShell.activeTab,
                  builder: (context, _) {
                    int activeIndex = MainShell.activeTab.value;

                    // If we are on message or notification screens, highlight nothing
                    if (currentRouteName == AppRoutes.messages ||
                        currentRouteName == AppRoutes.notifications) {
                      activeIndex = -1;
                    }

                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _GlobalSidebarItem(
                          icon: LucideIcons.home,
                          label: 'Home',
                          selected: activeIndex == 0,
                          onTap: () => _onSidebarItemTapped(context, 0),
                        ),
                        const SizedBox(height: 8),
                        _GlobalSidebarItem(
                          icon: LucideIcons.search,
                          label: 'Search',
                          selected: activeIndex == 1,
                          onTap: () => _onSidebarItemTapped(context, 1),
                        ),
                        const SizedBox(height: 8),
                        _GlobalSidebarItem(
                          icon: LucideIcons.heart,
                          label: 'Wishlist',
                          selected: activeIndex == 2,
                          onTap: () => _onSidebarItemTapped(context, 2),
                        ),
                        const SizedBox(height: 8),
                        _GlobalSidebarItem(
                          icon: LucideIcons.user,
                          label: 'Profile',
                          selected: activeIndex == 3,
                          onTap: () => _onSidebarItemTapped(context, 3),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Post Ad / Sell Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton.icon(
              onPressed: onPost,
              icon: const Icon(LucideIcons.plus, size: 18, color: AppColors.white),
              label: const Text(
                'Sell an Item',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlobalSidebarItem extends StatefulWidget {
  const _GlobalSidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_GlobalSidebarItem> createState() => _GlobalSidebarItemState();
}

class _GlobalSidebarItemState extends State<_GlobalSidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.forestGreen;
    const inactiveColor = AppColors.textPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: widget.selected
                ? activeColor.withValues(alpha: 0.08)
                : _isHovered
                    ? AppColors.surfaceMuted
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 22,
                color: widget.selected ? activeColor : inactiveColor,
              ),
              const SizedBox(width: 16),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w500,
                  color: widget.selected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
