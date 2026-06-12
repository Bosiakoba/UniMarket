import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/brand_background.dart';
import '../../routes/app_routes.dart';

class HomePreparingScreen extends StatefulWidget {
  const HomePreparingScreen({
    super.key,
    required this.onPrepare,
    this.nextRoute = AppRoutes.home,
    this.minimumDuration = const Duration(milliseconds: 2200),
  });

  final Future<void> Function() onPrepare;
  final String nextRoute;
  final Duration minimumDuration;

  static Route<void> route({
    required Future<void> Function() onPrepare,
    String nextRoute = AppRoutes.home,
  }) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (context, animation, secondaryAnimation) {
        return HomePreparingScreen(
          onPrepare: onPrepare,
          nextRoute: nextRoute,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  @override
  State<HomePreparingScreen> createState() => _HomePreparingScreenState();
}

class _HomePreparingScreenState extends State<HomePreparingScreen>
    with TickerProviderStateMixin {
  static const _messages = [
    'Setting up your campus feed…',
    'Finding deals near you…',
    'Loading verified sellers…',
    'Personalizing your experience…',
    'Almost ready…',
  ];

  late final AnimationController _pulseController;
  late final AnimationController _progressController;
  late final Animation<double> _pulse;
  late final Animation<double> _progress;

  Timer? _messageTimer;
  int _messageIndex = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.94, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: widget.minimumDuration,
    );
    _progress = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );

    _messageTimer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (!mounted || _error != null) return;
      setState(() => _messageIndex = (_messageIndex + 1) % _messages.length);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_runPrepare());
    });
  }

  Future<void> _runPrepare() async {
    final started = DateTime.now();
    _progressController.forward();

    try {
      await widget.onPrepare();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
      _progressController.stop();
      return;
    }

    final elapsed = DateTime.now().difference(started);
    final remaining = widget.minimumDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }

    if (!mounted) return;
    await _progressController.animateTo(
      1,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
    );
    if (!mounted) return;

    await Navigator.of(context).pushReplacementNamed(widget.nextRoute);
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),
                ScaleTransition(
                  scale: _pulse,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Image.asset(
                      AppAssets.splashLogo,
                      width: 88,
                      height: 88,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Preparing your home',
                  textAlign: TextAlign.center,
                  style: AppTypography.h2(color: AppColors.white),
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 360),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    _error ?? _messages[_messageIndex],
                    key: ValueKey(_error ?? _messageIndex),
                    textAlign: TextAlign.center,
                    style: AppTypography.body(
                      color: AppColors.white.withValues(alpha: 0.88),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                AnimatedBuilder(
                  animation: _progress,
                  builder: (context, _) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: _error != null ? null : _progress.value * 0.92,
                        minHeight: 6,
                        backgroundColor: AppColors.white.withValues(alpha: 0.16),
                        color: AppColors.white,
                      ),
                    );
                  },
                ),
                const Spacer(flex: 3),
                if (_error != null)
                  Column(
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _error = null;
                            _messageIndex = 0;
                          });
                          _progressController
                            ..reset()
                            ..forward();
                          unawaited(_runPrepare());
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.white,
                          side: BorderSide(
                            color: AppColors.white.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Text('Try again'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pushReplacementNamed(
                          AppRoutes.onboarding,
                        ),
                        child: Text(
                          'Back to onboarding',
                          style: AppTypography.body(
                            color: AppColors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  _LoadingDots(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final phase = (_controller.value * 3 + index) % 3;
            final opacity = 0.35 + (phase < 1 ? phase : 2 - phase) * 0.65;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
