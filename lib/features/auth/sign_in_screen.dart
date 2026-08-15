import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/data/stores/user_session_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/api_client_scope.dart';
import '../../core/widgets/auth_form_sheet.dart';
import '../../core/widgets/social_sign_in_button.dart';
import '../../core/widgets/uni_button.dart';
import '../../core/widgets/uni_text_field.dart';
import '../../core/widgets/user_session_scope.dart';
import '../../routes/app_routes.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, this.onSignedIn});

  final Future<void> Function()? onSignedIn;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController(
    text: kDebugMode ? UserSessionStore.demoEmail : '',
  );
  final _passwordController = TextEditingController(
    text: kDebugMode ? 'demo1234' : '',
  );

  var _bootstrapping = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final session = UserSessionScope.of(context);
    final client = ApiClientScope.of(context);

    final error = await session.signInWithApi(
      client: client,
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final route = session.postAuthRoute(client);

    if (route == AppRoutes.home) {
      setState(() => _bootstrapping = true);
      try {
        await widget.onSignedIn?.call();
      } finally {
        if (mounted) setState(() => _bootstrapping = false);
      }
      if (!mounted) return;
    }

    if (session.lastAuthError != null && route == AppRoutes.home) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Offline mode — could not reach API at ${client.baseUrl}',
          ),
        ),
      );
    }

    if (Navigator.canPop(context)) {
      if (route == AppRoutes.home) {
        Navigator.pop(context);
      } else {
        await Navigator.of(context).pushNamed(route);
        if (mounted) Navigator.pop(context);
      }
    } else {
      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  Future<void> _signInWithGoogle() async {
    final session = UserSessionScope.of(context);
    final client = ApiClientScope.of(context);

    final error = await session.signInWithGoogleApi(client: client);
    if (!mounted) return;

    if (error != null) {
      if (error.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
      return;
    }

    final route = session.postAuthRoute(client);
    if (route == AppRoutes.home) {
      setState(() => _bootstrapping = true);
      try {
        await widget.onSignedIn?.call();
      } finally {
        if (mounted) setState(() => _bootstrapping = false);
      }
      if (!mounted) return;
    }

    if (Navigator.canPop(context)) {
      if (route == AppRoutes.home) {
        Navigator.pop(context);
      } else {
        await Navigator.of(context).pushNamed(route);
        if (mounted) Navigator.pop(context);
      }
    } else {
      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  void _appleSignInStub() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple sign-in is coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = UserSessionScope.of(context);
    final loading = session.isSigningIn || _bootstrapping;

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        return Scaffold(
          body: AuthFormSheet(
            title: 'Sign In',
            children: [
              UniTextField(
                controller: _emailController,
                hint: 'University email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.mail_outline_rounded,
              ),
              const SizedBox(height: AppSpacing.md),
              UniTextField(
                controller: _passwordController,
                hint: 'Password',
                obscureText: true,
                prefixIcon: Icons.lock_outline_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.forgotPassword),
                  child: Text(
                    'Forgot password?',
                    style: AppTypography.caption(color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              UniButton(
                label: 'Sign In',
                width: 240,
                isLoading: loading,
                onPressed: loading ? null : _signIn,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Or continue with',
                textAlign: TextAlign.center,
                style: AppTypography.caption(),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  SocialSignInButton(
                    provider: SocialProvider.google,
                    onPressed:
                        loading ? () {} : _signInWithGoogle,
                  ),
                  const SizedBox(width: 12),
                  SocialSignInButton(
                    provider: SocialProvider.apple,
                    onPressed:
                        loading ? () {} : _appleSignInStub,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'New to Uni Market?',
                textAlign: TextAlign.center,
                style: AppTypography.body(),
              ),
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context)
                      .pushReplacementNamed(AppRoutes.signUp),
                  child: Text(
                    'Create account',
                    style: AppTypography.bodyBold(color: AppColors.forestGreen),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
