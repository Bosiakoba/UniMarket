import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/auth_form_sheet.dart';
import '../../core/widgets/social_sign_in_button.dart';
import '../../core/widgets/uni_button.dart';
import '../../core/widgets/uni_text_field.dart';
import '../../routes/app_routes.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthFormSheet(
        title: 'Sign In',
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
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed(AppRoutes.home),
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

