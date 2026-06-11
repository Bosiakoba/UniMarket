import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/api_client_scope.dart';
import '../../core/widgets/figma_asset.dart';
import '../../core/widgets/green_flow_layout.dart';
import '../../core/widgets/uni_button.dart';
import '../../core/widgets/user_session_scope.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../routes/app_routes.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key, this.onReadyForHome});

  final Future<void> Function()? onReadyForHome;

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  Timer? _pollTimer;
  var _checking = false;
  var _resent = false;

  @override
  void initState() {
    super.initState();
    unawaited(_sendVerificationEmail());
    _pollTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _checkVerification(silent: true),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    try {
      await FirebaseAuthService.sendEmailVerification();
      if (mounted) setState(() => _resent = true);
    } catch (_) {}
  }

  Future<void> _checkVerification({bool silent = false}) async {
    if (_checking) return;
    setState(() => _checking = true);

    try {
      final verified = await FirebaseAuthService.reloadEmailVerified();
      if (!mounted) return;

      if (verified) {
        _pollTimer?.cancel();
        await _continueAfterVerification();
        return;
      }

      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email not verified yet. Check your inbox.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _continueAfterVerification() async {
    final session = UserSessionScope.of(context);
    final client = ApiClientScope.of(context);
    final route = session.postAuthRoute(client);

    if (route == AppRoutes.home) {
      await widget.onReadyForHome?.call();
    }
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuthService.currentUser?.email ??
        UserSessionScope.of(context).currentUser?.email ??
        'your campus email';

    return GreenFlowLayout(
      showBackButton: false,
      illustration: const FigmaAsset(
        path: AppAssets.verificationIllustration,
        width: 280,
        height: 300,
        fit: BoxFit.contain,
      ),
      title: 'Verify your email',
      subtitle:
          'We sent a confirmation link to $email. Open it, then return here.',
      bottom: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UniButton(
            label: _checking ? 'Checking…' : 'I verified my email',
            variant: UniButtonVariant.secondary,
            isLoading: _checking,
            onPressed: _checking ? null : () => _checkVerification(),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _checking
                ? null
                : () async {
                    await _sendVerificationEmail();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _resent
                              ? 'Verification email sent again.'
                              : 'Verification email sent.',
                        ),
                      ),
                    );
                  },
            child: Text(
              'Resend email',
              style: AppTypography.bodyBold(color: AppColors.white),
            ),
          ),
        ],
      ),
      children: const [],
    );
  }
}
