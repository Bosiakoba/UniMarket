import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:image_picker/image_picker.dart';

import '../../core/models/seller_application.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/api_client_scope.dart';
import '../../core/widgets/seller_store_scope.dart';
import '../../core/widgets/uni_button.dart';
import '../../core/widgets/uni_text_field.dart';
import '../../core/widgets/user_session_scope.dart';
import 'seller_application_status_screen.dart';
import 'widgets/id_upload_card.dart';
import 'widgets/seller_email_otp_sheet.dart';
import 'widgets/seller_status_layout.dart';

class SellerApplicationScreen extends StatefulWidget {
  const SellerApplicationScreen({super.key, this.continueToListing = false});

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
  String? _idDocumentPath;
  String? _idDocumentMimeType;
  var _submitting = false;
  var _sendingOtp = false;
  var _emailVerified = false;
  String? _verifiedEmail;

  static final _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _storeController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = UserSessionScope.of(context).currentUser;
    if (user == null) return;
    if (_nameController.text.isEmpty) _nameController.text = user.fullName;
    if (_emailController.text.isEmpty) _emailController.text = user.email;
  }

  void _onEmailChanged(String value) {
    final trimmed = value.trim().toLowerCase();
    if (_emailVerified && trimmed != _verifiedEmail) {
      setState(() {
        _emailVerified = false;
        _verifiedEmail = null;
      });
    }
  }

  Future<void> _confirmStudentEmail() async {
    if (_sendingOtp) return;

    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      _showSnack('Enter a valid student email.');
      return;
    }

    setState(() => _sendingOtp = true);
    final client = ApiClientScope.of(context);

    try {
      await client.sendSellerEmailOtp(email);
    } catch (error) {
      if (!mounted) return;
      setState(() => _sendingOtp = false);
      _showSnack(error.toString());
      return;
    }

    if (!mounted) return;
    setState(() => _sendingOtp = false);

    final verified = await SellerEmailOtpSheet.show(
      context,
      email: email,
      onVerify: (code) async {
        try {
          await client.verifySellerEmailOtp(email: email, code: code);
          return null;
        } catch (error) {
          return error.toString();
        }
      },
    );

    if (!mounted || verified != true) return;
    setState(() {
      _emailVerified = true;
      _verifiedEmail = email.toLowerCase();
    });
    _showSnack('Student email confirmed.');
  }

  Future<void> _pickIdDocument() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (file == null) return;
    setState(() {
      _idDocumentPath = file.path;
      _idDocumentMimeType = file.mimeType;
      _idUploaded = true;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;

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
    if (!_emailVerified || _verifiedEmail != email.toLowerCase()) {
      _showSnack('Confirm your student email before submitting.');
      return;
    }
    if (!_idUploaded) {
      _showSnack('Upload your student ID to continue.');
      return;
    }

    setState(() => _submitting = true);
    final sellerStore = SellerStoreScope.of(context);
    final client = ApiClientScope.of(context);
    String? idDocumentUrl;

    try {
      if (_idDocumentPath != null) {
        idDocumentUrl = await client.uploadSellerDocument(
          _idDocumentPath!,
          mimeType: _idDocumentMimeType,
        );
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSnack(error.toString());
      return;
    }

    final application = SellerApplication(
      fullName: name,
      studentEmail: email,
      storeName: store,
      studentIdUploaded: true,
      appliedAt: DateTime.now(),
    );

    final error = await sellerStore.submitSellerApplicationRemote(
      data: application,
      client: client,
      idDocumentUrl: idDocumentUrl,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error != null) {
      _showSnack(error);
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SellerApplicationStatusScreen(
          continueToListing: widget.continueToListing,
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                          Text(
                            'Student email',
                            style: AppTypography.bodyBold(),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: UniTextField(
                                  hint: 'you@university.edu',
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.mail_outline_rounded,
                                  onChanged: _onEmailChanged,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: TextButton(
                                  onPressed: (_sendingOtp || _emailVerified)
                                      ? null
                                      : _confirmStudentEmail,
                                  style: TextButton.styleFrom(
                                    foregroundColor: _emailVerified
                                        ? AppColors.forestGreen
                                        : AppColors.forestGreen,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 16,
                                    ),
                                  ),
                                  child: _sendingOtp
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          _emailVerified ? 'Verified' : 'Confirm',
                                          style: AppTypography.bodyBold(
                                            color: AppColors.forestGreen,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                          if (_emailVerified) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Campus email confirmed.',
                              style: AppTypography.caption(
                                color: AppColors.forestGreen,
                              ),
                            ),
                          ],
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
                            onTap: _pickIdDocument,
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
                          detail: 'AI checks your ID, school, and verified email.',
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
                label: _submitting ? 'Submitting...' : 'Submit for review',
                variant: UniButtonVariant.green,
                isLoading: _submitting,
                onPressed: (_submitting || !_emailVerified) ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
