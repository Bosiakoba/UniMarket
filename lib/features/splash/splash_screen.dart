import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_preferences_scope.dart';
import '../../core/widgets/brand_background.dart';
import '../../core/widgets/user_session_scope.dart';
import '../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onBootstrapDemo});

  final VoidCallback? onBootstrapDemo;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scale = Tween<double>(begin: 0.82, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2400), _goNext);
  }

  void _goNext() {
    if (!mounted) return;

    final preferences = AppPreferencesScope.of(context);
    final session = UserSessionScope.of(context);

    if (session.isLoggedIn) {
      widget.onBootstrapDemo?.call();
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      return;
    }

    if (preferences.onboardingComplete) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.signIn);
      return;
    }

    Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandBackground(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fade.value,
                child: Transform.scale(scale: _scale.value, child: child),
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  AppAssets.splashLogo,
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 28),
                Text(
                  'Uni Market',
                  style: AppTypography.display().copyWith(fontSize: 42),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
