import 'package:flutter/material.dart';

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

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, this.onSignedIn});

  final Future<void> Function()? onSignedIn;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final session = UserSessionScope.of(context);
    final client = ApiClientScope.of(context);

    final error = await session.signUpWithApi(
      client: client,
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    final route = session.postAuthRoute(client);
    if (route == AppRoutes.home) {
      await widget.onSignedIn?.call();
    }
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final session = UserSessionScope.of(context);

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        return Scaffold(
          body: AuthFormSheet(
            title: 'Create Account',
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
              const SizedBox(height: AppSpacing.lg),
              UniButton(
                label: 'Sign Up',
                width: 240,
                isLoading: session.isSigningIn,
                onPressed: session.isSigningIn ? null : _signUp,
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
                    onPressed: session.isSigningIn ? () {} : _signUp,
                  ),
                  const SizedBox(width: 12),
                  SocialSignInButton(
                    provider: SocialProvider.apple,
                    onPressed: session.isSigningIn ? () {} : _signUp,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Already have an account?',
                textAlign: TextAlign.center,
                style: AppTypography.body(),
              ),
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context)
                      .pushReplacementNamed(AppRoutes.signIn),
                  child: Text(
                    'Sign in',
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
