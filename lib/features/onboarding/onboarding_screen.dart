import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/api_client_scope.dart';
import '../../core/widgets/app_preferences_scope.dart';
import '../../core/widgets/get_started_button.dart';
import '../../core/widgets/user_session_scope.dart';
import 'home_preparing_screen.dart';
import 'widgets/onboarding_card_stack.dart';
import 'widgets/onboarding_gradient.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.onBootstrap});

  final Future<void> Function()? onBootstrap;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;
  bool _isFinishing = false;

  static const _pages = [
    (
      title: 'Discover campus deals',
      body:
          'Swipe through listings from students around you — fashion, tech, books, and more.',
      arrow: 'assets/figma/onboarding/page1/arrow.svg',
    ),
    (
      title: 'Meet verified sellers',
      body:
          'Every profile is campus-only. Verified badges help you buy with confidence.',
      arrow: 'assets/figma/onboarding/page2/arrow.svg',
    ),
    (
      title: 'Earn while you study',
      body:
          'Sell what you don\'t need or offer services — turn your campus hustle into cash.',
      arrow: 'assets/figma/onboarding/page3/arrow.svg',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    final preferences = AppPreferencesScope.of(context);
    final session = UserSessionScope.of(context);
    final client = ApiClientScope.of(context);
    final bootstrap = widget.onBootstrap;

    preferences.completeOnboarding();
    if (!mounted) return;

    await Navigator.of(context).pushReplacement(
      HomePreparingScreen.route(
        onPrepare: () async {
          final error = await session.signInAnonymouslyWithApi(client: client);
          if (error != null) throw Exception(error);
          await bootstrap?.call();
        },
      ),
    );
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 480),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    unawaited(_finishOnboarding());
  }

  void _onSkip() {
    unawaited(_finishOnboarding());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final page = _controller.hasClients
              ? (_controller.page ?? _currentPage.toDouble())
              : _currentPage.toDouble();
          final index = page.round().clamp(0, _pages.length - 1);
          final offset = page - index;

          return OnboardingGradient(
            pageIndex: index,
            pageOffset: offset,
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                    child: Row(
                      children: [
                        Image.asset(
                          'assets/figma/onboarding/page1/logo.png',
                          width: 36,
                          height: 36,
                          cacheWidth: 72,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Uni Market',
                          style: AppTypography.bodyBold(color: AppColors.white),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _onSkip,
                          child: Text(
                            'Skip',
                            style: AppTypography.body(
                              color: AppColors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _pages.length,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (i) => setState(() => _currentPage = i),
                      itemBuilder: (context, pageIndex) {
                        final delta = pageIndex - page;
                        final opacity = (1 - delta.abs() * 0.55).clamp(0.0, 1.0);

                        return Opacity(
                          opacity: opacity,
                          child: Transform.translate(
                            offset: Offset(delta * 28, 0),
                            child: OnboardingCardStack(
                              pageIndex: pageIndex,
                              pageOffset: delta,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _BottomPanel(
                    title: _pages[_currentPage].title,
                    body: _pages[_currentPage].body,
                    pageCount: _pages.length,
                    currentPage: _currentPage,
                    isLastPage: _currentPage == _pages.length - 1,
                    isLoading: _isFinishing,
                    onNext: _onNext,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.title,
    required this.body,
    required this.pageCount,
    required this.currentPage,
    required this.isLastPage,
    required this.isLoading,
    required this.onNext,
  });

  final String title;
  final String body;
  final int pageCount;
  final int currentPage;
  final bool isLastPage;
  final bool isLoading;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 28, 28, AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        border: Border(
          top: BorderSide(color: AppColors.white.withValues(alpha: 0.22)),
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.h1(color: AppColors.white),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppTypography.body(
              color: AppColors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _PageDots(count: pageCount, index: currentPage),
          const SizedBox(height: AppSpacing.lg),
          GetStartedButton(
            label: isLastPage ? 'Get Started' : 'Continue',
            isLoading: isLoading,
            onPressed: isLoading ? null : onNext,
          ),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? AppColors.white
                : AppColors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
