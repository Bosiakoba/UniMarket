import 'package:flutter/material.dart';

import 'core/api/api_client.dart';
import 'core/config/api_config.dart';
import 'core/services/firebase_auth_service.dart';
import 'core/data/stores/app_preferences_store.dart';
import 'core/data/stores/message_store.dart';
import 'core/data/stores/notification_store.dart';
import 'core/data/stores/report_store.dart';
import 'core/data/stores/review_store.dart';
import 'core/data/stores/seller_store.dart';
import 'core/data/stores/user_session_store.dart';
import 'core/data/stores/wishlist_store.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/api_client_scope.dart';
import 'core/widgets/app_preferences_scope.dart';
import 'core/widgets/message_store_scope.dart';
import 'core/widgets/notification_store_scope.dart';
import 'core/widgets/report_store_scope.dart';
import 'core/widgets/review_store_scope.dart';
import 'core/widgets/seller_store_scope.dart';
import 'core/widgets/user_session_scope.dart';
import 'core/widgets/wishlist_store_scope.dart';
import 'core/widgets/mobile_viewport.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/auth/sign_up_screen.dart';
import 'features/auth/verification_screen.dart';
import 'features/messages/messages_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profile_setup/category_selection_screen.dart';
import 'features/profile_setup/profile_completion_screen.dart';
import 'features/shell/main_shell.dart';
import 'features/splash/splash_screen.dart';
import 'routes/app_routes.dart';

class UniMarketApp extends StatefulWidget {
  const UniMarketApp({super.key});

  @override
  State<UniMarketApp> createState() => _UniMarketAppState();
}

class _UniMarketAppState extends State<UniMarketApp> {
  final _apiClient = ApiClient(baseUrl: ApiConfig.baseUrl);
  final _preferences = AppPreferencesStore();
  final _session = UserSessionStore();
  final _sellerStore = SellerStore();
  final _messageStore = MessageStore();
  final _wishlistStore = WishlistStore();
  final _notificationStore = NotificationStore();
  final _reviewStore = ReviewStore();
  final _reportStore = ReportStore();

  Future<void> bootstrapAfterSignIn() async {
    final user = _session.currentUser;
    if (user == null) return;

    final token = await FirebaseAuthService.getIdToken();
    _apiClient.idToken = token;
    _apiClient.devUserId = token == null ? user.id : null;

    await _sellerStore.syncFromApi(_apiClient, user: user);
    await _wishlistStore.syncFromApi(_apiClient);
    await _messageStore.syncFromApi(_apiClient, userId: user.id);
  }

  @override
  Widget build(BuildContext context) {
    return ApiClientScope(
      client: _apiClient,
      child: AppPreferencesScope(
        store: _preferences,
        child: UserSessionScope(
          store: _session,
          child: SellerStoreScope(
            store: _sellerStore,
            child: MessageStoreScope(
              store: _messageStore,
              child: WishlistStoreScope(
                store: _wishlistStore,
                child: NotificationStoreScope(
                  store: _notificationStore,
                  child: ReviewStoreScope(
                    store: _reviewStore,
                    child: ReportStoreScope(
                      store: _reportStore,
                      child: MaterialApp(
                        title: 'Uni Market',
                        debugShowCheckedModeBanner: false,
                        theme: AppTheme.light,
                        builder: (context, child) => MobileViewport(
                          child: child ?? const SizedBox.shrink(),
                        ),
                        initialRoute: AppRoutes.splash,
                        routes: {
                          AppRoutes.splash: (_) => SplashScreen(
                                onBootstrap: bootstrapAfterSignIn,
                              ),
                          AppRoutes.onboarding: (_) =>
                              const OnboardingScreen(),
                          AppRoutes.signIn: (_) => SignInScreen(
                                onSignedIn: bootstrapAfterSignIn,
                              ),
                          AppRoutes.signUp: (_) => const SignUpScreen(),
                          AppRoutes.forgotPassword: (_) =>
                              const ForgotPasswordScreen(),
                          AppRoutes.verification: (_) =>
                              const VerificationScreen(),
                          AppRoutes.profileCompletion: (_) =>
                              const ProfileCompletionScreen(),
                          AppRoutes.categorySelection: (_) =>
                              const CategorySelectionScreen(),
                          AppRoutes.home: (_) => const MainShell(),
                          AppRoutes.messages: (_) => const MessagesScreen(),
                          AppRoutes.notifications: (_) =>
                              const NotificationsScreen(),
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
