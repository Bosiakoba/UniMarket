import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/session_mode.dart';
import '../data/stores/message_store.dart';
import '../data/stores/notification_store.dart';
import '../data/stores/seller_store.dart';
import '../data/stores/user_session_store.dart';
import '../models/app_notification.dart';

class PushNotificationService {
  static bool _configuredForegroundListener = false;

  static Future<void> registerDevice({
    required ApiClient client,
    required NotificationStore notificationStore,
    SellerStore? sellerStore,
    UserSessionStore? sessionStore,
    MessageStore? messageStore,
  }) async {
    if (!isLiveSession(client)) return;

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await client.registerFcmToken(token: token, platform: _platformLabel);
      }

      if (!_configuredForegroundListener) {
        _configuredForegroundListener = true;
        FirebaseMessaging.onMessage.listen((message) async {
          final notification = message.notification;
          notificationStore.push(
            AppNotification(
              id:
                  message.messageId ??
                  'fcm-${DateTime.now().millisecondsSinceEpoch}',
              title: notification?.title ?? 'UniMarket',
              body: notification?.body ?? '',
              timeLabel: 'Just now',
              section: 'Today',
              type: _typeFromData(message.data['type']),
              targetId: message.data['targetId'],
              actionLabel: _actionLabelFor(message.data['type']),
            ),
          );

          await _refreshStoresForMessage(
            client: client,
            data: message.data,
            notificationStore: notificationStore,
            sellerStore: sellerStore,
            sessionStore: sessionStore,
            messageStore: messageStore,
          );
        });

        FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
          if (token.isEmpty) return;
          try {
            await client.registerFcmToken(
              token: token,
              platform: _platformLabel,
            );
          } catch (_) {}
        });
      }
    } catch (_) {
      // Push support is optional in local/dev builds.
    }
  }

  static Future<void> _refreshStoresForMessage({
    required ApiClient client,
    required Map<String, dynamic> data,
    required NotificationStore notificationStore,
    SellerStore? sellerStore,
    UserSessionStore? sessionStore,
    MessageStore? messageStore,
  }) async {
    if (!isLiveSession(client)) return;

    final type = data['type'] as String?;
    final user = sessionStore?.currentUser;

    try {
      if (sellerStore != null &&
          sessionStore != null &&
          user != null &&
          (type == 'sellerApplication' || type == 'verification')) {
        await sellerStore.refreshApplicationStatus(
          client: client,
          onUserUpdated: sessionStore.setCurrentUser,
        );
      }

      if (messageStore != null && user != null && type == 'message') {
        await messageStore.syncFromApi(client, userId: user.id);
      }

      if (sellerStore != null &&
          sessionStore != null &&
          user != null &&
          type == 'listing') {
        await sellerStore.syncFromApi(client, user: user);
      }

      await notificationStore.syncFromApi(client);
    } catch (_) {
      // Foreground push already updated the inbox locally.
    }
  }

  static NotificationType _typeFromData(String? value) {
    return switch (value) {
      'verification' => NotificationType.verification,
      'listing' => NotificationType.listing,
      'message' => NotificationType.message,
      'wishlist' => NotificationType.wishlist,
      'sellerApplication' => NotificationType.sellerApplication,
      _ => NotificationType.system,
    };
  }

  static String? _actionLabelFor(String? value) {
    return switch (value) {
      'message' => 'Open chat',
      'listing' => 'View listing',
      'verification' => 'View status',
      'sellerApplication' => 'View status',
      _ => null,
    };
  }

  static String get _platformLabel {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }
}
