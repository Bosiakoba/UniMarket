import 'dart:convert';
import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/models/university.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/api_client_scope.dart';
import '../../core/widgets/brand_background.dart';
import '../../core/widgets/figma_asset.dart';
import '../../core/widgets/searchable_selection_sheet.dart';
import '../../core/widgets/uni_button.dart';
import '../../core/widgets/uni_text_field.dart';
import '../../core/widgets/user_session_scope.dart';
import '../../routes/app_routes.dart';

class ProfileCompletionScreen extends StatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  State<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState extends State<ProfileCompletionScreen> {
  final _nameController = TextEditingController();
  final _universityController = TextEditingController();
  final _campusController = TextEditingController();
  final _phoneController = TextEditingController();
  var _hydrated = false;
  var _saving = false;

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

      if (userUni == 'State University' || userUni.isEmpty) {
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
    _hydrated = true;
    final user = UserSessionScope.of(context).currentUser;
    if (user != null) {
      _nameController.text = user.fullName;
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

    final route = session.postAuthRoute(client);
    if (Navigator.canPop(context)) {
      if (route == AppRoutes.home) {
        Navigator.pop(context);
      } else {
        await Navigator.of(context).pushNamed(route);
        if (mounted) Navigator.pop(context);
      }
    } else {
      Navigator.of(context).pushReplacementNamed(route);
    }
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
                      _SelectionField(
                        hint: _isLoadingData ? 'Loading universities...' : 'Select University',
                        value: _universityController.text,
                        prefixIcon: Icons.school_outlined,
                        enabled: !_isLoadingData,
                        onTap: _selectUniversity,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SelectionField(
                        hint: _selectedUniversity == null
                            ? 'Select University first'
                            : 'Select Campus',
                        value: _campusController.text,
                        prefixIcon: Icons.location_city_outlined,
                        enabled: _selectedUniversity != null,
                        onTap: _selectCampus,
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
