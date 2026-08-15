import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/university.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/api_client_scope.dart';
import '../../core/widgets/searchable_selection_sheet.dart';
import '../../core/widgets/uni_button.dart';
import '../../core/widgets/uni_text_field.dart';
import '../../core/widgets/user_session_scope.dart';
import '../../core/api/media_url.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _universityController = TextEditingController();
  final _campusController = TextEditingController();
  final _phoneController = TextEditingController();
  var _saving = false;
  var _hydrated = false;

  final _picker = ImagePicker();
  String? _avatarUrl;
  var _uploadingAvatar = false;

  List<University> _universities = [];
  University? _selectedUniversity;
  var _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadUniversityData();
  }

  Future<void> _loadUniversityData() async {
    try {
      final jsonStr = await DefaultAssetBundle.of(context).loadString(
        'universites-in-gh-data/ghana_universities.json',
      );
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final uniList = (data['universities'] as List<dynamic>)
          .map((e) => University.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _universities = uniList;
        _isLoadingData = false;
        _matchInitialSelection();
      });
    } catch (_) {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  void _matchInitialSelection() {
    final user = UserSessionScope.of(context).currentUser;
    if (user != null && _universities.isNotEmpty) {
      final userUni = user.university.trim();
      final userCampus = user.campus.trim();

      if (userUni.isEmpty) {
        _universityController.clear();
        _selectedUniversity = null;
        _campusController.clear();
        return;
      }

      final matchingUni = _universities.cast<University?>().firstWhere(
        (u) => u!.name.toLowerCase() == userUni.toLowerCase() ||
               u.shortName.toLowerCase() == userUni.toLowerCase(),
        orElse: () => _universities.cast<University?>().firstWhere(
          (u) => u!.name.toLowerCase().contains(userUni.toLowerCase()),
          orElse: () => null,
        ),
      );

      if (matchingUni != null) {
        _selectedUniversity = matchingUni;
        _universityController.text = matchingUni.name;

        final matchingCampus = matchingUni.campuses.cast<Campus?>().firstWhere(
          (c) => c!.name.toLowerCase() == userCampus.toLowerCase(),
          orElse: () => matchingUni.campuses.cast<Campus?>().firstWhere(
            (c) => c!.name.toLowerCase().contains(userCampus.toLowerCase()),
            orElse: () => null,
          ),
        );

        if (matchingCampus != null) {
          _campusController.text = matchingCampus.name;
        } else {
          _campusController.clear();
        }
      } else {
        _universityController.clear();
        _selectedUniversity = null;
        _campusController.clear();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) return;
    final user = UserSessionScope.of(context).currentUser;
    if (user == null) return;
    _nameController.text = user.fullName;
    _phoneController.text = user.phone ?? '';
    _avatarUrl = user.avatarUrl;
    _hydrated = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _campusController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    if (_uploadingAvatar) return;

    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (file == null) return;
    if (!mounted) return;

    setState(() {
      _uploadingAvatar = true;
    });

    final client = ApiClientScope.of(context);
    try {
      final url = await client.uploadAvatar(file.path, mimeType: file.mimeType);
      if (!mounted) return;
      setState(() {
        _avatarUrl = url;
        _uploadingAvatar = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar uploaded successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingAvatar = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload avatar: $e')),
      );
    }
  }

  void _selectUniversity() {
    if (_isLoadingData) return;

    final items = _universities.map((uni) {
      return SearchableSelectionSheetItem(
        title: uni.name,
        subtitle: uni.shortName.isNotEmpty ? uni.shortName : null,
        value: uni,
      );
    }).toList();

    SearchableSelectionSheet.show(
      context,
      title: 'Select University',
      searchHint: 'Search universities...',
      items: items,
    ).then((uni) {
      if (uni != null && uni is University) {
        setState(() {
          _selectedUniversity = uni;
          _universityController.text = uni.name;
          _campusController.clear();
        });
      }
    });
  }

  void _selectCampus() {
    if (_selectedUniversity == null) return;

    final items = _selectedUniversity!.campuses.map((campus) {
      return SearchableSelectionSheetItem(
        title: campus.name,
        subtitle: '${campus.town}, ${campus.region}',
        value: campus,
      );
    }).toList();

    SearchableSelectionSheet.show(
      context,
      title: 'Select Campus',
      searchHint: 'Search campuses...',
      items: items,
    ).then((campus) {
      if (campus != null && campus is Campus) {
        setState(() {
          _campusController.text = campus.name;
        });
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;

    final session = UserSessionScope.of(context);
    if (!session.isLoggedIn) return;

    setState(() => _saving = true);
    final error = await session.updateProfileWithApi(
      client: ApiClientScope.of(context),
      fullName: _nameController.text,
      university: _universityController.text,
      campus: _campusController.text,
      phone: _phoneController.text,
      avatarUrl: _avatarUrl,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final session = UserSessionScope.of(context);
    final user = session.currentUser;
    final isSeller = user?.isSeller ?? false;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Edit profile', style: AppTypography.h3()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: _pickAvatar,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 2.5),
                    ),
                    child: ClipOval(
                      child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                          ? Image.network(
                              MediaUrlResolver.resolve(_avatarUrl!),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.person,
                                size: 50,
                                color: AppColors.textTertiary,
                              ),
                            )
                          : const Icon(
                              Icons.person_outline,
                              size: 50,
                              color: AppColors.textTertiary,
                            ),
                    ),
                  ),
                ),
                if (_uploadingAvatar)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.forestGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isSeller) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Approved sellers cannot change name, university, or campus details.',
                      style: AppTypography.caption(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          UniTextField(
            controller: _nameController,
            hint: 'Full name',
            prefixIcon: Icons.person_outline,
            enabled: !isSeller,
          ),
          const SizedBox(height: AppSpacing.md),
          _SelectionField(
            hint: _isLoadingData ? 'Loading universities...' : 'Select University',
            value: _universityController.text,
            prefixIcon: Icons.school_outlined,
            enabled: !_isLoadingData && !isSeller,
            onTap: _selectUniversity,
          ),
          const SizedBox(height: AppSpacing.md),
          _SelectionField(
            hint: _selectedUniversity == null
                ? 'Select University first'
                : 'Select Campus',
            value: _campusController.text,
            prefixIcon: Icons.location_city_outlined,
            enabled: _selectedUniversity != null && !isSeller,
            onTap: _selectCampus,
          ),
          const SizedBox(height: AppSpacing.md),
          UniTextField(
            controller: _phoneController,
            hint: 'Phone number',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
          ),
          const SizedBox(height: AppSpacing.xl),
          UniButton(
            label: 'Save changes',
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}

class _SelectionField extends StatelessWidget {
  final String hint;
  final String value;
  final IconData prefixIcon;
  final VoidCallback onTap;
  final bool enabled;

  const _SelectionField({
    required this.hint,
    required this.value,
    required this.prefixIcon,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value.isNotEmpty;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.6,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(prefixIcon, color: AppColors.textTertiary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasValue ? value : hint,
                  style: AppTypography.body(
                    color: hasValue ? AppColors.textPrimary : AppColors.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.arrow_drop_down,
                color: AppColors.textTertiary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
