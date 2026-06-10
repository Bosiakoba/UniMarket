import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/models/seller_application.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/seller_store_scope.dart';
import '../../core/widgets/uni_button.dart';
import '../../core/widgets/uni_text_field.dart';
import 'seller_application_status_screen.dart';
import 'widgets/id_upload_card.dart';
import 'widgets/seller_status_layout.dart';

class SellerApplicationScreen extends StatefulWidget {
  const SellerApplicationScreen({
    super.key,
    this.continueToListing = false,
  });

  final bool continueToListing;

  @override
  State<SellerApplicationScreen> createState() =>
      _SellerApplicationScreenState();
}

class _SellerApplicationScreenState extends State<SellerApplicationScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _storeController = TextEditingController();
  bool _idUploaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _storeController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final store = _storeController.text.trim();

    if (name.isEmpty) {
      _showSnack('Enter your full name.');
      return;
    }
    if (!email.contains('@')) {
      _showSnack('Enter a valid student email.');
      return;
    }
    if (store.isEmpty) {
      _showSnack('Enter your store or business name.');
      return;
    }
    if (!_idUploaded) {
      _showSnack('Upload your student ID to continue.');
      return;
    }

    SellerStoreScope.of(context).submitSellerApplication(
      SellerApplication(
        fullName: name,
        studentEmail: email,
        storeName: store,
        studentIdUploaded: true,
        appliedAt: DateTime.now(),
      ),
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SellerApplicationStatusScreen(
          continueToListing: widget.continueToListing,
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(LucideIcons.arrowLeft),
                  ),
                  Text('Apply to sell', style: AppTypography.h3()),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Join the campus marketplace',
                      style: AppTypography.h2(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Submit once with your student details. Posting unlocks '
                      'after a quick campus review — the verified badge comes later.',
                      style: AppTypography.body(),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Campus details', style: AppTypography.h3()),
                          const SizedBox(height: 16),
                          Text('Full name', style: AppTypography.bodyBold()),
                          const SizedBox(height: 8),
                          UniTextField(
                            hint: 'As shown on student ID',
                            controller: _nameController,
                            prefixIcon: Icons.person_outline,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text('Student email', style: AppTypography.bodyBold()),
                          const SizedBox(height: 8),
                          UniTextField(
                            hint: 'you@university.edu',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.mail_outline_rounded,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Store / business name',
                            style: AppTypography.bodyBold(),
                          ),
                          const SizedBox(height: 8),
                          UniTextField(
                            hint: 'e.g. Alex Campus Tech',
                            controller: _storeController,
                            prefixIcon: Icons.storefront_outlined,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text('Student ID', style: AppTypography.bodyBold()),
                          const SizedBox(height: 8),
                          IdUploadCard(
                            uploaded: _idUploaded,
                            onTap: () => setState(() => _idUploaded = true),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const SellerStatusStepCard(
                      steps: [
                        SellerStatusStep(
                          label: 'Submit application',
                          detail: 'Takes about 2 minutes.',
                          state: SellerStatusStepState.active,
                        ),
                        SellerStatusStep(
                          label: 'Campus review',
                          detail: 'We verify your student ID and email.',
                          state: SellerStatusStepState.upcoming,
                        ),
                        SellerStatusStep(
                          label: 'Start posting',
                          detail: 'List items once approved.',
                          state: SellerStatusStepState.upcoming,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, bottom + 16),
              child: UniButton(
                label: 'Submit for review',
                variant: UniButtonVariant.green,
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
