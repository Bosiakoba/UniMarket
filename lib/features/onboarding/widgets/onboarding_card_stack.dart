import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Pinterest-style stacked glass cards — listing, seller, and earn profiles.
class OnboardingCardStack extends StatelessWidget {
  const OnboardingCardStack({
    super.key,
    required this.pageIndex,
    required this.pageOffset,
  });

  final int pageIndex;
  final double pageOffset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 420),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(animation),
              child: child,
            ),
          );
        },
        child: switch (pageIndex) {
          0 => _ListingStack(key: const ValueKey(0), pageOffset: pageOffset),
          1 => _SellerStack(key: const ValueKey(1), pageOffset: pageOffset),
          _ => _EarnStack(key: const ValueKey(2), pageOffset: pageOffset),
        },
      ),
    );
  }
}

class _ListingStack extends StatelessWidget {
  const _ListingStack({super.key, required this.pageOffset});

  final double pageOffset;

  static const _cards = [
    _StackCardData(
      image: AppAssets.ob1Collage8,
      title: 'Campus Sneakers',
      subtitle: 'Fashion · 0.4 km',
      price: 'GH₵ 280',
      tag: 'Like new',
    ),
    _StackCardData(
      image: AppAssets.ob1Collage6,
      title: 'MacBook Pro 13"',
      subtitle: 'Electronics · Verified',
      price: 'GH₵ 4,200',
      tag: 'Hot deal',
    ),
    _StackCardData(
      image: AppAssets.ob1Collage3,
      title: 'Textbook Bundle',
      subtitle: 'Books · Main Campus',
      price: 'GH₵ 120',
      tag: 'Level 200',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _CardFan(
      pageOffset: pageOffset,
      cards: _cards
          .map(
            (c) => _MarketplaceCard(
              image: c.image,
              title: c.title,
              subtitle: c.subtitle,
              price: c.price,
              tag: c.tag,
            ),
          )
          .toList(),
    );
  }
}

class _SellerStack extends StatelessWidget {
  const _SellerStack({super.key, required this.pageOffset});

  final double pageOffset;

  static const _cards = [
    _StackCardData(
      image: AppAssets.ob2Sneaker,
      title: 'Ama K.',
      subtitle: 'State University',
      price: '48 sales',
      tag: 'Verified',
      verified: true,
    ),
    _StackCardData(
      image: AppAssets.ob2Perfume,
      title: 'Kwesi M.',
      subtitle: 'Engineering Hall',
      price: '32 sales',
      tag: 'Top rated',
      verified: true,
    ),
    _StackCardData(
      image: AppAssets.ob2Produce,
      title: 'Efua A.',
      subtitle: 'Hostel Block C',
      price: '19 sales',
      tag: 'New seller',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _CardFan(
      pageOffset: pageOffset,
      cards: _cards
          .map(
            (c) => _ProfileCard(
              image: c.image,
              name: c.title,
              campus: c.subtitle,
              stat: c.price,
              tag: c.tag,
              verified: c.verified,
            ),
          )
          .toList(),
    );
  }
}

class _EarnStack extends StatelessWidget {
  const _EarnStack({super.key, required this.pageOffset});

  final double pageOffset;

  @override
  Widget build(BuildContext context) {
    return _CardFan(
      pageOffset: pageOffset,
      cards: [
        _EarnCard(
          image: AppAssets.ob3MoneyTop,
          amount: 'GH₵ 240',
          label: 'Earned this week',
          tag: 'Design gigs',
        ),
        _EarnCard(
          image: AppAssets.ob3MoneyBottom,
          amount: 'GH₵ 85',
          label: 'Saved on textbooks',
          tag: 'Campus deals',
        ),
        _EarnCard(
          image: AppAssets.ob1Collage2,
          amount: 'GH₵ 1.2k',
          label: 'Total campus sales',
          tag: 'All time',
        ),
      ],
    );
  }
}

class _StackCardData {
  const _StackCardData({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.tag,
    this.verified = false,
  });

  final String image;
  final String title;
  final String subtitle;
  final String price;
  final String tag;
  final bool verified;
}

class _CardFan extends StatelessWidget {
  const _CardFan({required this.pageOffset, required this.cards});

  final double pageOffset;
  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    assert(cards.length == 3);

    final spread = pageOffset.clamp(-1.0, 1.0);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        _positionedCard(
          index: 0,
          child: cards[0],
          baseAngle: -0.14,
          baseDx: -52,
          baseDy: 18,
          scale: 0.86,
          spread: spread,
        ),
        _positionedCard(
          index: 1,
          child: cards[1],
          baseAngle: 0.1,
          baseDx: 54,
          baseDy: 24,
          scale: 0.9,
          spread: spread,
        ),
        _positionedCard(
          index: 2,
          child: cards[2],
          baseAngle: 0,
          baseDx: 0,
          baseDy: 0,
          scale: 1,
          spread: spread,
          isFront: true,
        ),
      ],
    );
  }

  Widget _positionedCard({
    required int index,
    required Widget child,
    required double baseAngle,
    required double baseDx,
    required double baseDy,
    required double scale,
    required double spread,
    bool isFront = false,
  }) {
    final drift = spread * (isFront ? 36 : 18);
    final lift = isFront ? -spread.abs() * 8 : spread.abs() * 4;

    return Positioned(
      child: Transform.translate(
        offset: Offset(baseDx + drift, baseDy + lift),
        child: Transform.rotate(
          angle: baseAngle + spread * 0.06,
          child: Transform.scale(
            scale: scale + (isFront ? spread.abs() * 0.02 : 0),
            child: child,
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
