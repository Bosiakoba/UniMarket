import 'package:flutter/material.dart';

import 'core/data/stores/message_store.dart';
import 'core/data/stores/seller_store.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/message_store_scope.dart';
import 'core/widgets/mobile_viewport.dart';
import 'core/widgets/seller_store_scope.dart';
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
  final _messageStore = MessageStore();
  final _sellerStore = SellerStore();

  @override
  Widget build(BuildContext context) {
    return MessageStoreScope(
      store: _messageStore,
      child: SellerStoreScope(
        store: _sellerStore,
        child: MaterialApp(
          title: 'Uni Market',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          builder: (context, child) =>
              MobileViewport(child: child ?? const SizedBox.shrink()),
          initialRoute: AppRoutes.splash,
          routes: {
            AppRoutes.splash: (_) => const SplashScreen(),
            AppRoutes.onboarding: (_) => const OnboardingScreen(),
            AppRoutes.signIn: (_) => const SignInScreen(),
            AppRoutes.signUp: (_) => const SignUpScreen(),
            AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
            AppRoutes.verification: (_) => const VerificationScreen(),
            AppRoutes.profileCompletion: (_) =>
                const ProfileCompletionScreen(),
            AppRoutes.categorySelection: (_) =>
                const CategorySelectionScreen(),
            AppRoutes.home: (_) => const MainShell(),
            AppRoutes.messages: (_) => const MessagesScreen(),
            AppRoutes.notifications: (_) => const NotificationsScreen(),
          },
        ),
      ),
    );
  }
}
