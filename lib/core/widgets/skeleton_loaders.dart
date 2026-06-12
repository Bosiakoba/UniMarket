import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../../features/listings/widgets/listing_card.dart';

/// Shimmering placeholder block used across loading states.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1 + 2 * _controller.value, 0),
              end: Alignment(1 + 2 * _controller.value, 0),
              colors: const [
                AppColors.surfaceMuted,
                Color(0xFFFAFBF9),
                AppColors.surfaceMuted,
              ],
              stops: const [0.2, 0.5, 0.8],
            ),
          ),
        );
      },
    );
  }
}

class HomeFeedSkeleton extends StatelessWidget {
  const HomeFeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 220, height: 18, borderRadius: 8),
                SizedBox(height: 10),
                SkeletonBox(width: 160, height: 14, borderRadius: 8),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 188,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, _) => const _CompactListingSkeleton(),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: const [
                SkeletonBox(width: 120, height: 18, borderRadius: 8),
                Spacer(),
                SkeletonBox(width: 56, height: 14, borderRadius: 8),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: ListingGrid.sliverDelegate,
            delegate: SliverChildBuilderDelegate(
              (_, _) => const _GridListingSkeleton(),
              childCount: 4,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactListingSkeleton extends StatelessWidget {
  const _CompactListingSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonBox(width: 140, height: 120, borderRadius: 14),
          SizedBox(height: 8),
          SkeletonBox(width: 110, height: 12, borderRadius: 6),
          SizedBox(height: 6),
          SkeletonBox(width: 72, height: 14, borderRadius: 6),
        ],
      ),
    );
  }
}

class _GridListingSkeleton extends StatelessWidget {
  const _GridListingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Expanded(child: SkeletonBox(borderRadius: 12)),
        SizedBox(height: 8),
        SkeletonBox(width: double.infinity, height: 12, borderRadius: 6),
        SizedBox(height: 6),
        SkeletonBox(width: 72, height: 14, borderRadius: 6),
      ],
    );
  }
}

class ListingDetailSkeleton extends StatelessWidget {
  const ListingDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonBox(
            width: double.infinity,
            height: 280,
            borderRadius: 16,
          ),
          SizedBox(height: 18),
          SkeletonBox(width: double.infinity, height: 24, borderRadius: 8),
          SizedBox(height: 10),
          SkeletonBox(width: 120, height: 28, borderRadius: 8),
          SizedBox(height: 12),
          SkeletonBox(width: 160, height: 16, borderRadius: 8),
          SizedBox(height: 16),
          SkeletonBox(width: double.infinity, height: 14, borderRadius: 6),
          SizedBox(height: 8),
          SkeletonBox(width: double.infinity, height: 14, borderRadius: 6),
          SizedBox(height: 8),
          SkeletonBox(width: 220, height: 14, borderRadius: 6),
          SizedBox(height: 20),
          _SellerCardSkeleton(),
        ],
      ),
    );
  }
}

class _SellerCardSkeleton extends StatelessWidget {
  const _SellerCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: const [
          SkeletonBox(width: 48, height: 48, borderRadius: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 120, height: 14, borderRadius: 6),
                SizedBox(height: 8),
                SkeletonBox(width: 90, height: 12, borderRadius: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReviewsSectionSkeleton extends StatelessWidget {
  const ReviewsSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Reviews', style: AppTypography.bodyBold()),
            const Spacer(),
            const SkeletonBox(width: 72, height: 12, borderRadius: 6),
          ],
        ),
        const SizedBox(height: 12),
        const SkeletonBox(width: 140, height: 16, borderRadius: 8),
        const SizedBox(height: 16),
        const ReviewTileSkeleton(),
        const SizedBox(height: 12),
        const ReviewTileSkeleton(showDivider: false),
      ],
    );
  }
}

class ReviewTileSkeleton extends StatelessWidget {
  const ReviewTileSkeleton({super.key, this.showDivider = true});

  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(width: 36, height: 36, borderRadius: 18),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 100, height: 12, borderRadius: 6),
                  SizedBox(height: 8),
                  SkeletonBox(width: double.infinity, height: 12, borderRadius: 6),
                  SizedBox(height: 6),
                  SkeletonBox(width: 180, height: 12, borderRadius: 6),
                ],
              ),
            ),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 12),
          Divider(color: AppColors.border.withValues(alpha: 0.7), height: 1),
        ],
      ],
    );
  }
}
