import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/uni_button.dart';
import '../../core/widgets/uni_text_field.dart';
import '../../core/widgets/user_session_scope.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _universityController;
  late final TextEditingController _campusController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = UserSessionScope.of(context).currentUser;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _universityController = TextEditingController(text: user?.university ?? '');
    _campusController = TextEditingController(text: user?.campus ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _campusController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _save() {
    final session = UserSessionScope.of(context);
    if (!session.isLoggedIn) return;

    session.updateProfile(
      fullName: _nameController.text.trim(),
      university: _universityController.text.trim(),
      campus: _campusController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Edit profile', style: AppTypography.h3()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
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
          const SizedBox(height: AppSpacing.xl),
          UniButton(label: 'Save changes', onPressed: _save),
        ],
      ),
    );
  }
}
