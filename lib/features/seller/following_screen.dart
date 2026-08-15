import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/app_user.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/api_client_scope.dart';
import 'seller_profile_screen.dart';

class FollowingScreen extends StatefulWidget {
  final String userId;

  const FollowingScreen({super.key, required this.userId});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  List<AppUser>? _following;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    try {
      final client = ApiClientScope.of(context);
      final list = await client.getFollowing(widget.userId);
      if (mounted) {
        setState(() {
          _following = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load following';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Following', style: AppTypography.h3()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: AppTypography.body(color: AppColors.dealRed)))
              : _following!.isEmpty
                  ? Center(child: Text('Not following anyone', style: AppTypography.body(color: AppColors.textSecondary)))
                  : ListView.builder(
                      itemCount: _following!.length,
                      itemBuilder: (context, index) {
                        final user = _following![index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.surfaceMuted,
                            child: Text(
                              user.displayInitial,
                              style: AppTypography.body(color: AppColors.forestGreen),
                            ),
                          ),
                          title: Text(user.fullName, style: AppTypography.body()),
                          subtitle: Text(user.university, style: AppTypography.caption(color: AppColors.textSecondary)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SellerProfileScreen(
                                  sellerName: user.fullName,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
    );
  }
}
