import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/api_client_scope.dart';
import '../../core/widgets/brand_background.dart';
import '../../core/widgets/figma_asset.dart';
import '../../core/widgets/uni_button.dart';
import '../../core/widgets/uni_text_field.dart';
import '../../core/widgets/user_session_scope.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _nameController = TextEditingController();
  final _universityController = TextEditingController(
    text: 'State University',
  );
  final _campusController = TextEditingController(text: 'Main Campus');
  final _phoneController = TextEditingController();
  var _hydrated = false;
  var _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) return;
    _hydrated = true;
    final user = UserSessionScope.of(context).currentUser;
    if (user != null) {
      _nameController.text = user.fullName;
      _universityController.text = user.university;
      _campusController.text = user.campus;
      _phoneController.text = user.phone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _campusController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_saving) return;

    setState(() => _saving = true);
    final session = UserSessionScope.of(context);
    final client = ApiClientScope.of(context);

    final error = await session.completeProfileWithApi(
      client: client,
      fullName: _nameController.text,
      university: _universityController.text,
      campus: _campusController.text,
      phone: _phoneController.text,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    Navigator.of(context).pushReplacementNamed(
      session.postAuthRoute(client),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrandBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Complete your profile',
                        textAlign: TextAlign.center,
                        style: AppTypography.h1(color: AppColors.white),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Help buyers trust you on campus',
                        textAlign: TextAlign.center,
                        style: AppTypography.body(
                          color: AppColors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const FigmaAsset(
                        path: AppAssets.profileProgressMeter,
                        width: 240,
                        height: 240,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      UniTextField(
                        controller: _nameController,
                        hint: 'Full name',
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      UniTextField(
                        controller: _universityController,
                        hint: 'University',
                        prefixIcon: Icons.school_outlined,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      UniTextField(
                        controller: _campusController,
                        hint: 'Campus',
                        prefixIcon: Icons.location_city_outlined,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      UniTextField(
                        controller: _phoneController,
                        hint: 'Phone number',
                        keyboardType: TextInputType.phone,
                        prefixIcon: Icons.phone_outlined,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                child: UniButton(
                  label: 'Continue',
                  width: 240,
                  variant: UniButtonVariant.secondary,
                  isLoading: _saving,
                  onPressed: _saving ? null : _continue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
