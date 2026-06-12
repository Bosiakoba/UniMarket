import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../api/api_client.dart';
import '../data/stores/user_session_store.dart';
import '../services/firebase_auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/api_client_scope.dart';
import '../widgets/uni_button.dart';
import '../widgets/user_session_scope.dart';
import '../../routes/app_routes.dart';

/// True when the user is browsing without a full email/password account.
bool isGuestSession({
  required UserSessionStore session,
  required ApiClient client,
}) {
  if (!session.isLoggedIn) return true;
  return FirebaseAuthService.isAnonymous;
}

/// Prompts for sign-in or sign-up when a gated action is attempted.
/// Returns `true` if the user is registered (or just signed in).
Future<bool> ensureRegisteredAccount(
  BuildContext context, {
  String? reason,
}) async {
  final session = UserSessionScope.of(context);
  final client = ApiClientScope.of(context);
  if (!isGuestSession(session: session, client: client)) {
    return true;
  }

  final choice = await AuthGateSheet.show(
    context,
    reason: reason,
  );
  if (!context.mounted || choice == null) return false;

  if (choice == AuthGateChoice.signIn) {
    await Navigator.of(context).pushNamed(AppRoutes.signIn);
  } else {
    await Navigator.of(context).pushNamed(AppRoutes.signUp);
  }

  if (!context.mounted) return false;
  return !isGuestSession(session: session, client: client);
}

enum AuthGateChoice { signIn, signUp }

class AuthGateSheet extends StatelessWidget {
  const AuthGateSheet({super.key, this.reason});

  final String? reason;

  static Future<AuthGateChoice?> show(
    BuildContext context, {
    String? reason,
  }) {
    return showModalBottomSheet<AuthGateChoice>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AuthGateSheet(reason: reason),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottom + 24),
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
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Icon(LucideIcons.shield, size: 28, color: AppColors.forestGreen),
          const SizedBox(height: 12),
          Text('Sign in to continue', style: AppTypography.h3()),
          const SizedBox(height: 8),
          Text(
            reason ??
                'Create a campus account or sign in when you are ready to '
                'message sellers, save items, or start selling.',
            style: AppTypography.body(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          UniButton(
            label: 'Sign in',
            variant: UniButtonVariant.green,
            onPressed: () =>
                Navigator.of(context).pop(AuthGateChoice.signIn),
          ),
          const SizedBox(height: 10),
          UniButton(
            label: 'Create account',
            variant: UniButtonVariant.secondary,
            onPressed: () =>
                Navigator.of(context).pop(AuthGateChoice.signUp),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Keep browsing',
              style: AppTypography.body(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
