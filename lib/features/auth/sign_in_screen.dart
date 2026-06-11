import 'package:flutter/material.dart';

import '../../core/data/stores/user_session_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/auth_form_sheet.dart';
import '../../core/widgets/social_sign_in_button.dart';
import '../../core/widgets/uni_button.dart';
import '../../core/widgets/uni_text_field.dart';
import '../../core/widgets/user_session_scope.dart';
import '../../routes/app_routes.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, this.onSignedIn});

  final VoidCallback? onSignedIn;

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController(
    text: UserSessionStore.demoEmail,
  );
  final _passwordController = TextEditingController(text: 'demo1234');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() {
    final error = UserSessionScope.of(context).signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    widget.onSignedIn?.call();
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  void _socialSignIn() {
    final error = UserSessionScope.of(context).signIn(
      email: UserSessionStore.demoEmail,
      password: 'oauth',
    );
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    widget.onSignedIn?.call();
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
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
          UniButton(label: 'Sign In', width: 240, onPressed: _signIn),
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
                onPressed: _socialSignIn,
              ),
              const SizedBox(width: 12),
              SocialSignInButton(
                provider: SocialProvider.apple,
                onPressed: _socialSignIn,
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
              onTap: () =>
                  Navigator.of(context).pushReplacementNamed(AppRoutes.signUp),
              child: Text(
                'Create account',
                style: AppTypography.bodyBold(color: AppColors.forestGreen),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
