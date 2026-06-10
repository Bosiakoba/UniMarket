import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../home/home_screen.dart';
import '../profile/profile_screen.dart';
import '../search/search_screen.dart';
import '../sell/sell_entry.dart';
import '../wishlist/wishlist_screen.dart';
import 'main_shell_scope.dart';

const kFloatingNavHeight = 58.0;
const kFloatingNavMargin = 12.0;
const kPostButtonSize = 52.0;

double floatingChromeBottomInset(BuildContext context) {
  final bottom = MediaQuery.paddingOf(context).bottom;
  return bottom + kFloatingNavMargin + kFloatingNavHeight + 16;
}

double homeScrollBottomInset(BuildContext context) =>
    floatingChromeBottomInset(context);

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _goToTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final showFloatingChrome = !keyboardOpen;
    final navBottom = bottom + kFloatingNavMargin;

    final screens = [
      const HomeScreen(),
      const SearchScreen(),
      const WishlistScreen(),
      const ProfileScreen(),
    ];

    return MainShellScope(
      goToTab: _goToTab,
      child: Scaffold(
        backgroundColor: AppColors.white,
        extendBody: true,
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: IndexedStack(index: _currentIndex, children: screens),
            ),
            if (showFloatingChrome)
              Positioned(
                left: 20,
                right: 20,
                bottom: navBottom,
                child: _FloatingNavBar(
                  currentIndex: _currentIndex,
                  onTap: _goToTab,
                  onPost: () => SellEntry.openPostFlow(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.onPost,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onPost;

  static const _leftItems = [LucideIcons.home, LucideIcons.search];
  static const _rightItems = [LucideIcons.heart, LucideIcons.user];

  static const _leftIndices = [0, 1];
  static const _rightIndices = [2, 3];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 8,
      shadowColor: AppColors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(32),
      child: Container(
        height: kFloatingNavHeight,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.black,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_leftItems.length, (i) {
                  return _NavIcon(
                    icon: _leftItems[i],
                    selected: currentIndex == _leftIndices[i],
                    onTap: () => onTap(_leftIndices[i]),
                  );
                }),
              ),
            ),
            _PostNavButton(onTap: onPost),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_rightItems.length, (i) {
                  return _NavIcon(
                    icon: _rightItems[i],
                    selected: currentIndex == _rightIndices[i],
                    onTap: () => onTap(_rightIndices[i]),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: 44,
        height: 44,
        child: selected
            ? DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: AppColors.black),
              )
            : Icon(
                icon,
                size: 22,
                color: AppColors.white.withValues(alpha: 0.85),
              ),
      ),
    );
  }
}

class _PostNavButton extends StatelessWidget {
  const _PostNavButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: AppColors.forestGreen,
        elevation: 4,
        shadowColor: AppColors.black.withValues(alpha: 0.25),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: kPostButtonSize,
            height: kPostButtonSize,
            child: Icon(
              LucideIcons.plus,
              color: AppColors.white,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
