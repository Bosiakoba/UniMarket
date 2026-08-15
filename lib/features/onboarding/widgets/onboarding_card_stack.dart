import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Pinterest-style stacked glass cards for onboarding with continuous peeling animation.
class OnboardingCardStack extends StatelessWidget {
  const OnboardingCardStack({
    super.key,
    required this.scrollPosition,
  });

  final double scrollPosition;

  @override
  Widget build(BuildContext context) {
    // We have exactly 3 cards representing the 3 pages.
    final cards = [
      const _MarketplaceCard(
        image: AppAssets.ob2Sneaker,
        title: 'Campus Sneakers',
        subtitle: 'Fashion · 0.4 km',
        price: 'GH₵ 280',
        tag: 'Like new',
      ),
      const _ProfileCard(
        image: AppAssets.ob1Collage8,
        name: 'Ama K.',
        campus: 'State University',
        stat: '48 sales',
        tag: 'Verified',
        verified: true,
      ),
      const _EarnCard(
        image: AppAssets.ob3MoneyTop,
        amount: 'GH₵ 240',
        label: 'Earned this week',
        tag: 'Design gigs',
      ),
    ];

    return SizedBox(
      height: 400,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        // Render from back to front (reverse order) so the top card draws last.
        children: List.generate(3, (i) {
          // reverse the index for rendering (2, 1, 0)
          final cardIndex = 2 - i;
          return _ContinuousPositionedCard(
            cardIndex: cardIndex,
            scrollPosition: scrollPosition,
            child: cards[cardIndex],
          );
        }),
      ),
    );
  }
}

class _ContinuousPositionedCard extends StatelessWidget {
  const _ContinuousPositionedCard({
    required this.cardIndex,
    required this.scrollPosition,
    required this.child,
  });

  final int cardIndex;
  final double scrollPosition;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Relative position of this card compared to the current scroll.
    // If scrollPosition == 0 (Page 1) and cardIndex == 0, rel = 0 (Front)
    // If scrollPosition == 0 and cardIndex == 1, rel = 1 (Middle)
    // If scrollPosition == 0 and cardIndex == 2, rel = 2 (Back)
    // If scrollPosition == 1 (Page 2) and cardIndex == 0, rel = -1 (Flown away left)
    // If scrollPosition == 1 and cardIndex == 1, rel = 0 (Front)
    final rel = cardIndex - scrollPosition;

    // If it's flown way off to the left, don't render it.
    if (rel < -1.0) return const SizedBox.shrink();

    // Calculate layout parameters based on relative position.
    double scale = 1.0;
    double dx = 0.0;
    double dy = 0.0;
    double angle = 0.0;
    double opacity = 1.0;

    if (rel <= 0) {
      // The card is in front and is flying away to the left.
      // rel goes from 0 to -1.
      final progress = -rel; // 0 to 1
      
      // Fly away to the left and up, rotate a bit
      dx = -300 * progress;
      dy = -100 * progress;
      angle = -0.2 * progress;
      
      // Fade out quickly during the first half of the swipe
      opacity = (1.0 - progress * 2).clamp(0.0, 1.0);
      scale = 1.0 + (progress * 0.1);
    } else if (rel <= 1.0) {
      // The card is moving from Middle to Front.
      // rel goes from 1 to 0.
      // Middle state: scale = 0.9, dx = 54, dy = 24, angle = 0.1
      // Front state: scale = 1.0, dx = 0, dy = 0, angle = 0.0
      scale = 1.0 - (0.1 * rel);
      dx = 54 * rel;
      dy = 24 * rel;
      angle = 0.1 * rel;
      opacity = 1.0;
    } else if (rel <= 2.0) {
      // The card is moving from Back to Middle.
      // rel goes from 2 to 1.
      final t = rel - 1.0; // 1 to 0
      // Back state: scale = 0.86, dx = -52, dy = 18, angle = -0.14
      // Middle state: scale = 0.9, dx = 54, dy = 24, angle = 0.1
      scale = 0.9 - (0.04 * t);
      dx = 54 - (106 * t);
      dy = 24 - (6 * t);
      angle = 0.1 - (0.24 * t);
      
      // Fade in from back
      opacity = (1.0 - (t * 0.5)).clamp(0.0, 1.0);
    } else {
      // The card is beyond Back, hide it or place it behind Back.
      scale = 0.86;
      dx = -52;
      dy = 18;
      angle = -0.14;
      opacity = 0.0;
    }

    if (opacity <= 0.0) return const SizedBox.shrink();

    return Positioned(
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(
            angle: angle,
            child: Transform.scale(
              scale: scale,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassShell extends StatelessWidget {
  const _GlassShell({required this.child});

  final Widget child;

  static const double _width = 252;
  static const double _height = 340;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: _width,
          height: _height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.42), width: 1.2),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.white.withValues(alpha: 0.28),
                AppColors.white.withValues(alpha: 0.08),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.28),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MarketplaceCard extends StatelessWidget {
  const _MarketplaceCard({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.tag,
  });

  final String image;
  final String title;
  final String subtitle;
  final String price;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return _GlassShell(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(image, fit: BoxFit.cover, cacheWidth: 500),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.black.withValues(alpha: 0.15),
                    AppColors.black.withValues(alpha: 0.72),
                  ],
                  stops: const [0.35, 0.62, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: _Chip(label: tag),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.h3(color: AppColors.white)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.caption(
                      color: AppColors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(price, style: AppTypography.price(color: AppColors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.image,
    required this.name,
    required this.campus,
    required this.stat,
    required this.tag,
    this.verified = false,
  });

  final String image;
  final String name;
  final String campus;
  final String stat;
  final String tag;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return _GlassShell(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(image, fit: BoxFit.cover, cacheWidth: 500),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.black.withValues(alpha: 0.05),
                    AppColors.black.withValues(alpha: 0.55),
                    AppColors.black.withValues(alpha: 0.82),
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: _Chip(label: tag),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name, style: AppTypography.h2(color: AppColors.white)),
                      if (verified) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: AppColors.verifiedGold,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            LucideIcons.badgeCheck,
                            size: 14,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.graduationCap,
                        size: 14,
                        color: AppColors.white,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          campus,
                          style: AppTypography.caption(
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    stat,
                    style: AppTypography.bodyBold(color: AppColors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarnCard extends StatelessWidget {
  const _EarnCard({
    required this.image,
    required this.amount,
    required this.label,
    required this.tag,
  });

  final String image;
  final String amount;
  final String label;
  final String tag;

  @override
  Widget build(BuildContext context) {
    return _GlassShell(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(image, fit: BoxFit.cover, cacheWidth: 500),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.forestGreen.withValues(alpha: 0.35),
                    AppColors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 14,
              child: _Chip(label: tag, accent: AppColors.verifiedGold),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(amount, style: AppTypography.display(color: AppColors.white).copyWith(fontSize: 34)),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: AppTypography.body(
                      color: AppColors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.accent});

  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: (accent ?? AppColors.white).withValues(alpha: accent == null ? 0.22 : 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTypography.caption(
          color: accent == null ? AppColors.white : AppColors.black,
        ),
      ),
    );
  }
}
