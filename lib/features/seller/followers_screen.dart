import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/models/app_user.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/api_client_scope.dart';
import 'seller_profile_screen.dart'; // To navigate to other users

class FollowersScreen extends StatefulWidget {
  final String userId;

  const FollowersScreen({super.key, required this.userId});

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  List<AppUser>? _followers;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    try {
      final client = ApiClientScope.of(context);
      final list = await client.getFollowers(widget.userId);
      if (mounted) {
        setState(() {
          _followers = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load followers';
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
        title: Text('Followers', style: AppTypography.h3()),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: AppTypography.body(color: AppColors.dealRed)))
              : _followers!.isEmpty
                  ? Center(child: Text('No followers yet', style: AppTypography.body(color: AppColors.textSecondary)))
                  : ListView.builder(
                      itemCount: _followers!.length,
                      itemBuilder: (context, index) {
                        final user = _followers![index];
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
                            // Navigate to seller profile using their name or id
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SellerProfileScreen(
                                  sellerName: user.fullName, // Might need adjust if name isn't unique
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
