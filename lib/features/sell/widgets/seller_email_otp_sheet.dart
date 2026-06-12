import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/uni_button.dart';
import '../../../core/widgets/uni_text_field.dart';

class SellerEmailOtpSheet extends StatefulWidget {
  const SellerEmailOtpSheet({
    super.key,
    required this.email,
    required this.onVerify,
  });

  final String email;
  final Future<String?> Function(String code) onVerify;

  static Future<bool?> show(
    BuildContext context, {
    required String email,
    required Future<String?> Function(String code) onVerify,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SellerEmailOtpSheet(email: email, onVerify: onVerify),
      ),
    );
  }

  @override
  State<SellerEmailOtpSheet> createState() => _SellerEmailOtpSheetState();
}

class _SellerEmailOtpSheetState extends State<SellerEmailOtpSheet> {
  final _codeController = TextEditingController();
  var _verifying = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_verifying) return;

    final code = _codeController.text.trim();
    if (code.length != 4) {
      _showSnack('Enter the 4-digit code from your email.');
      return;
    }

    setState(() => _verifying = true);
    final error = await widget.onVerify(code);
    if (!mounted) return;
    setState(() => _verifying = false);

    if (error != null) {
      _showSnack(error);
      return;
    }

    Navigator.of(context).pop(true);
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Confirm campus email', style: AppTypography.h3()),
            const SizedBox(height: 8),
            Text(
              'We sent a 4-digit code to ${widget.email}.',
              style: AppTypography.body(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            UniTextField(
              hint: '4-digit code',
              controller: _codeController,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.pin_outlined,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            UniButton(
              label: 'Verify email',
              variant: UniButtonVariant.green,
              isLoading: _verifying,
              onPressed: _verifying ? null : _verify,
            ),
          ],
        ),
      ),
    );
  }
}
