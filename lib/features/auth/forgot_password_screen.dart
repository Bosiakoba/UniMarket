import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/widgets/green_flow_layout.dart';
import '../../core/widgets/uni_button.dart';
import '../../core/widgets/uni_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  var _sending = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your campus email.')),
      );
      return;
    }

    setState(() => _sending = true);
    final error = await FirebaseAuthService.sendPasswordResetEmail(email);
    if (!mounted) return;
    setState(() => _sending = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset email sent.')),
    );
    Navigator.of(context).pop();
  }

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
        isLoading: _sending,
        onPressed: _sending ? null : _sendResetLink,
      ),
      children: [
        UniTextField(
          controller: _emailController,
          hint: 'University email',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.mail_outline_rounded,
        ),
      ],
    );
  }
}
