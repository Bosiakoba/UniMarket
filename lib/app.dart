import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'core/api/api_client.dart';
import 'core/models/app_user.dart';
import 'core/config/api_config.dart';
import 'core/services/chat_signalr_service.dart';
import 'core/services/firebase_auth_service.dart';
import 'core/services/push_notification_service.dart';
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

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<UniMarketApp> createState() => _UniMarketAppState();
}

class _UniMarketAppState extends State<UniMarketApp> with WidgetsBindingObserver {
  final _apiClient = ApiClient(baseUrl: ApiConfig.baseUrl);
  final _preferences = AppPreferencesStore();
  final _session = UserSessionStore();
  final _sellerStore = SellerStore();
  final _messageStore = MessageStore();
  final _wishlistStore = WishlistStore();
  final _notificationStore = NotificationStore();
  final _reviewStore = ReviewStore();
  final _reportStore = ReportStore();
  final _signalRService = ChatSignalRService();
  Timer? _badgePollTimer;

  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _preferences.init();
    _authSubscription = FirebaseAuth.instance.idTokenChanges().listen((user) async {
      if (user != null) {
        final token = await user.getIdToken();
        _apiClient.idToken = token;
        _apiClient.devUserId = null;
      } else {
        _apiClient.idToken = null;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    _signalRService.dispose();
    _badgePollTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshLiveSessionData());
    }
  }

  Future<void> _refreshLiveSessionData() async {
    final user = _session.currentUser;
    if (user == null) return;

    final token = await FirebaseAuthService.getIdToken();
    _apiClient.idToken = token;
    _apiClient.devUserId = token == null ? user.id : null;

    await Future.wait([
      _sellerStore.refreshApplicationStatus(
        client: _apiClient,
        onUserUpdated: _session.setCurrentUser,
      ).catchError((_) {}),
      _notificationStore.syncFromApi(_apiClient),
      _messageStore.syncFromApi(_apiClient, userId: user.id),
    ]);

    _connectSignalR(withUser: user, token: token);
  }

  Future<void> bootstrapAfterSignIn() async {
    final user = _session.currentUser;
    if (user == null) return;

    final token = await FirebaseAuthService.getIdToken();
    _apiClient.idToken = token;
    _apiClient.devUserId = token == null ? user.id : null;

    _reviewStore.clear(reseedOfflineMocks: false);
    _reportStore.clear();

    AppUser activeUser = user;
    if (token != null) {
      try {
        activeUser = await _apiClient.fetchMe();
        _session.setCurrentUser(activeUser);
      } catch (_) {}
    }

    await Future.wait([
      _sellerStore.syncFromApi(_apiClient, user: activeUser),
      _wishlistStore.syncFromApi(_apiClient),
      _messageStore.syncFromApi(_apiClient, userId: activeUser.id),
      _notificationStore.syncFromApi(_apiClient),
    ]);

    await PushNotificationService.registerDevice(
      client: _apiClient,
      notificationStore: _notificationStore,
      sellerStore: _sellerStore,
      sessionStore: _session,
      messageStore: _messageStore,
    );

    _connectSignalR(withUser: activeUser, token: token);
    _startBadgePolling(userId: activeUser.id);
  }

  void _startBadgePolling({required String userId}) {
    _badgePollTimer?.cancel();
    _badgePollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (FirebaseAuthService.currentUser == null) return;
      Future.wait([
        _messageStore.syncFromApi(_apiClient, userId: userId).catchError((_) {}),
        _notificationStore.syncFromApi(_apiClient).catchError((_) {}),
      ]);
    });
  }

  void _connectSignalR({required AppUser withUser, String? token}) {
    _signalRService.connect(
      client: _apiClient,
      messageStore: _messageStore,
      currentUserId: withUser.id,
      idToken: token,
    ).catchError((_) {
      debugPrint('[SignalR] Connection failed on bootstrap');
    });
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
                        themeMode: ThemeMode.light,
                        navigatorKey: UniMarketApp.navigatorKey,
                        navigatorObservers: [AppRouteObserver()],
                        builder: (context, child) => MobileViewport(
                          child: child ?? const SizedBox.shrink(),
                        ),
                        onGenerateInitialRoutes: (initialRoute) {
                          return [
                            MaterialPageRoute<void>(
                              settings: const RouteSettings(name: AppRoutes.splash),
                              builder: (context) => SplashScreen(onBootstrap: bootstrapAfterSignIn),
                            ),
                          ];
                        },
                        initialRoute: AppRoutes.splash,
                        routes: {
                          AppRoutes.splash: (_) =>
                              SplashScreen(onBootstrap: bootstrapAfterSignIn),
                          AppRoutes.onboarding: (_) => OnboardingScreen(
                            onBootstrap: bootstrapAfterSignIn,
                          ),
                          AppRoutes.signIn: (_) =>
                              SignInScreen(onSignedIn: bootstrapAfterSignIn),
                          AppRoutes.signUp: (_) =>
                              SignUpScreen(onSignedIn: bootstrapAfterSignIn),
                          AppRoutes.forgotPassword: (_) =>
                              const ForgotPasswordScreen(),
                          AppRoutes.verification: (_) => VerificationScreen(
                            onReadyForHome: bootstrapAfterSignIn,
                          ),
                          AppRoutes.profileCompletion: (_) =>
                              const ProfileCompletionScreen(),
                          AppRoutes.categorySelection: (_) =>
                              CategorySelectionScreen(
                                onReadyForHome: bootstrapAfterSignIn,
                              ),
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
