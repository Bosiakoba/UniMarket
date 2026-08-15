import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/api_client_scope.dart';
import '../../core/widgets/app_preferences_scope.dart';
import '../../core/widgets/brand_background.dart';
import '../../core/widgets/brand_logo_mark.dart';
import '../../core/widgets/user_session_scope.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onBootstrap});

  final Future<void> Function()? onBootstrap;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
  bool _hasBootstrapped = false;

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasBootstrapped) {
      _hasBootstrapped = true;
      _bootstrapAndNavigate();
    }
  }

  void _precacheAppAssets() {
    final assetsToPrecache = [
      AppAssets.authLogo,
      AppAssets.forgetPasswordIllustration,
      AppAssets.splashLogo,
      AppAssets.brandLogo,
      AppAssets.ob1Collage1,
      AppAssets.ob1Collage2,
      AppAssets.ob1Collage3,
      AppAssets.ob1Collage4,
      AppAssets.ob1Collage5,
      AppAssets.ob1Collage6,
      AppAssets.ob1Collage7,
      AppAssets.ob1Collage8,
      AppAssets.ob1Collage9,
      AppAssets.ob1Logo,
      AppAssets.ob2Logo,
      AppAssets.ob2Sneaker,
      AppAssets.ob2Produce,
      AppAssets.ob2Perfume,
      AppAssets.ob3Logo,
      AppAssets.ob3MoneyTop,
      AppAssets.ob3MoneyBottom,
      AppAssets.verificationIllustration,
      AppAssets.profileProgressMeter,
      AppAssets.profileProgressMeterCategories,
    ];
    for (final path in assetsToPrecache) {
      precacheImage(AssetImage(path), context).catchError((_) {});
    }
  }

  Future<void> _bootstrapAndNavigate() async {
    final startTime = DateTime.now();

    final preferences = AppPreferencesScope.of(context);
    final session = UserSessionScope.of(context);
    final client = ApiClientScope.of(context);

    _precacheAppAssets();

    if (!session.isLoggedIn) {
      await session.restoreFromFirebase(client: client);
    }

    if (!session.isLoggedIn &&
        preferences.onboardingComplete &&
        FirebaseAuthService.currentUser == null) {
      await session.signInAnonymouslyWithApi(client: client);
    }

    if (session.isLoggedIn) {
      await widget.onBootstrap?.call();
    }

    final elapsed = DateTime.now().difference(startTime).inMilliseconds;
    final remaining = 800 - elapsed;
    if (remaining > 0) {
      await Future<void>.delayed(Duration(milliseconds: remaining));
    }

    if (!mounted) return;

    if (session.isLoggedIn) {
      final route = session.postAuthRoute(client);
      Navigator.of(context).pushReplacementNamed(route);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
    }
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
                const BrandLogoMark(size: 168, showOuterRing: false),
                const SizedBox(height: 28),
                Text(
                  'UniMarket',
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
