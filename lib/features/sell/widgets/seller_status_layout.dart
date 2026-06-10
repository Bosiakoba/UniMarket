import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

enum SellerStatusTone { neutral, pending, success, verified }

class SellerStatusLayout extends StatelessWidget {
  const SellerStatusLayout({
    super.key,
    required this.title,
    required this.badgeLabel,
    required this.tone,
    this.subtitle,
    this.heroIcon = LucideIcons.store,
    this.onBack,
    this.bottom,
    this.children = const [],
  });

  final String title;
  final String? subtitle;
  final String badgeLabel;
  final SellerStatusTone tone;
  final IconData heroIcon;
  final VoidCallback? onBack;
  final List<Widget> children;
  final Widget? bottom;

  Color get _accent => switch (tone) {
        SellerStatusTone.pending => const Color(0xFFE8A317),
        SellerStatusTone.success => AppColors.forestGreen,
        SellerStatusTone.verified => AppColors.verifiedGold,
        SellerStatusTone.neutral => AppColors.forestGreen,
      };

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                    icon: const Icon(LucideIcons.arrowLeft),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    _HeroBadge(
                      icon: heroIcon,
                      tone: tone,
                      accent: _accent,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _accent.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Text(
                        badgeLabel,
                        style: AppTypography.caption(color: _accent).copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTypography.h1(),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: AppTypography.body(),
                      ),
                    ],
                    const SizedBox(height: 28),
                    ...children,
                  ],
                ),
              ),
            ),
            if (bottom != null)
              Padding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, bottomInset + 16),
                child: bottom!,
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.icon,
    required this.tone,
    required this.accent,
  });

  final IconData icon;
  final SellerStatusTone tone;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            accent.withValues(alpha: 0.22),
            accent.withValues(alpha: 0.06),
            AppColors.white,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 46, color: accent),
          if (tone == SellerStatusTone.verified)
            const Positioned(
              right: 22,
              bottom: 22,
              child: Icon(
                LucideIcons.badgeCheck,
                size: 28,
                color: AppColors.verifiedGold,
              ),
            ),
          if (tone == SellerStatusTone.pending)
            Positioned(
              right: 20,
              bottom: 20,
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.clock3,
                  size: 18,
                  color: accent,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class SellerStatusStepCard extends StatelessWidget {
  const SellerStatusStepCard({
    super.key,
    required this.steps,
  });

  final List<SellerStatusStep> steps;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            _StepRow(step: steps[i]),
            if (i < steps.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class SellerStatusStep {
  const SellerStatusStep({
    required this.label,
    required this.detail,
    required this.state,
  });

  final String label;
  final String detail;
  final SellerStatusStepState state;
}

enum SellerStatusStepState { done, active, upcoming }

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});

  final SellerStatusStep step;

  @override
  Widget build(BuildContext context) {
    final color = switch (step.state) {
      SellerStatusStepState.done => AppColors.forestGreen,
      SellerStatusStepState.active => const Color(0xFFE8A317),
      SellerStatusStepState.upcoming => AppColors.textTertiary,
    };

    final icon = switch (step.state) {
      SellerStatusStepState.done => LucideIcons.checkCircle2,
      SellerStatusStepState.active => LucideIcons.loader,
      SellerStatusStepState.upcoming => LucideIcons.circle,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.label, style: AppTypography.bodyBold()),
              const SizedBox(height: 2),
              Text(step.detail, style: AppTypography.caption()),
            ],
          ),
        ),
      ],
    );
  }
}

class SellerCriteriaCard extends StatelessWidget {
  const SellerCriteriaCard({
    super.key,
    required this.items,
  });

  final List<SellerCriteriaItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What you need', style: AppTypography.h3()),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: item.met
                          ? AppColors.forestGreen.withValues(alpha: 0.12)
                          : AppColors.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.met ? LucideIcons.check : LucideIcons.minus,
                      size: 14,
                      color: item.met
                          ? AppColors.forestGreen
                          : AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.label, style: AppTypography.bodyBold()),
                        Text(item.detail, style: AppTypography.caption()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SellerCriteriaItem {
  const SellerCriteriaItem({
    required this.label,
    required this.detail,
    required this.met,
  });

  final String label;
  final String detail;
  final bool met;
}
