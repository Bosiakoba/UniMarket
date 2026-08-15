import '../models/app_user.dart';
import '../../routes/app_routes.dart';
import '../services/firebase_auth_service.dart';

abstract final class OnboardingNavigation {
  static String routeFor({
    required AppUser? user,
    required bool usesFirebaseAuth,
  }) {
    if (user == null) return AppRoutes.signIn;

    if (FirebaseAuthService.isAnonymous) {
      return AppRoutes.home;
    }

    if (usesFirebaseAuth && !FirebaseAuthService.emailVerified) {
      return AppRoutes.verification;
    }
    if (!user.profileComplete) {
      return AppRoutes.profileCompletion;
    }
    if (user.interestCategories.isEmpty) {
      return AppRoutes.categorySelection;
    }
    return AppRoutes.home;
  }
}
