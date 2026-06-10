import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/widgets/green_flow_layout.dart';
import '../../core/widgets/uni_button.dart';
import '../../core/widgets/uni_text_field.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GreenFlowLayout(
      illustration: Image.asset(
        AppAssets.forgetPasswordIllustration,
        width: 280,
        height: 300,
        fit: BoxFit.contain,
      ),
      title: 'Forgotten Password',
      subtitle: 'Enter your campus email and we\'ll send a reset link.',
      bottom: UniButton(
        label: 'Send Reset Link',
        width: 240,
        variant: UniButtonVariant.secondary,
        onPressed: () => Navigator.of(context).pop(),
      ),
      children: const [
        UniTextField(
          hint: 'University email',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.mail_outline_rounded,
        ),
      ],
    );
  }
}
