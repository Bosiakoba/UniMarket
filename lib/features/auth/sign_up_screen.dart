import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/auth_form_sheet.dart';
import '../../core/widgets/social_sign_in_button.dart';
import '../../core/widgets/uni_button.dart';
import '../../core/widgets/uni_text_field.dart';
import '../../routes/app_routes.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthFormSheet(
        title: 'Create Account',
        children: [
          const UniTextField(
            hint: 'University email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          const UniTextField(
            hint: 'Password',
            obscureText: true,
            prefixIcon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: AppSpacing.lg),
          UniButton(
            label: 'Sign Up',
            width: 240,
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.verification),
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
                onPressed: () => Navigator.of(context)
                    .pushReplacementNamed(AppRoutes.home),
              ),
              const SizedBox(width: 12),
              SocialSignInButton(
                provider: SocialProvider.apple,
                onPressed: () => Navigator.of(context)
                    .pushReplacementNamed(AppRoutes.home),
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
              onTap: () =>
                  Navigator.of(context).pushReplacementNamed(AppRoutes.signIn),
              child: Text(
                'Sign in',
                style: AppTypography.bodyBold(color: AppColors.forestGreen),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

