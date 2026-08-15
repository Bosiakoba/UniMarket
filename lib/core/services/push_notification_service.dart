import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app.dart';
import '../../features/messages/chat_screen.dart';
import '../api/api_client.dart';
import '../api/session_mode.dart';
import '../data/stores/message_store.dart';
import '../data/stores/notification_store.dart';
import '../data/stores/seller_store.dart';
import '../data/stores/user_session_store.dart';
import '../models/app_notification.dart';
import '../navigation/notification_navigation.dart';

/// VAPID key for Web Push (public key, safe to expose client-side).
/// Generated from Firebase Console > Cloud Messaging > Web Push certificates.
const String _vapidKey =
    'BDJqhxpvOpcpQT7Fx8McP298kXqCFrhARgIqv695-UUlL8P5EDQxxeapfan9t7xAJ5mx_xXuF2Pr0xnNzDWdRD8';

/// Keys inside the FCM data payload that carry full message details
/// so the client can display a message instantly without an API call.
const _fcmKeyMessageId = 'messageId';
const _fcmKeySenderId = 'senderId';
const _fcmKeySenderName = 'senderName';
const _fcmKeyContent = 'content';
const _fcmKeyMessageType = 'messageType';

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

      // For web, pass the VAPID key to enable push messaging.
      final token = kIsWeb
          ? await messaging.getToken(vapidKey: _vapidKey)
          : await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await client.registerFcmToken(token: token, platform: _platformLabel);
      }

      if (!_configuredForegroundListener) {
        _configuredForegroundListener = true;

        FirebaseMessaging.onMessage.listen((message) async {
          final notification = message.notification;
          final data = message.data;

          // For message type, apply the message directly from data payload
          if (data['type'] == 'message' &&
              data[_fcmKeyMessageId] != null &&
              data[_fcmKeyContent] != null &&
              data['targetId'] != null &&
              sessionStore?.currentUser != null &&
              messageStore != null) {
            final userId = sessionStore!.currentUser!.id;
            messageStore.applyRealTimeMessage({
              'chatId': data['targetId']!,
              'messageId': data[_fcmKeyMessageId]!,
              'senderId': data[_fcmKeySenderId] ?? '',
              'senderName': data[_fcmKeySenderName] ?? '',
              'content': data[_fcmKeyContent]!,
              'messageType': data[_fcmKeyMessageType] ?? 'text',
            }, currentUserId: userId);
          }

          if (data['type'] != 'message') {
            notificationStore.push(
              AppNotification(
                id:
                    message.messageId ??
                    'fcm-${DateTime.now().millisecondsSinceEpoch}',
                title: notification?.title ?? 'UniMarket',
                body: notification?.body ?? '',
                timeLabel: 'Just now',
                section: 'Today',
                type: _typeFromData(data['type']),
                targetId: data['targetId'],
                actionLabel: _actionLabelFor(data['type']),
              ),
            );
          }

          await _refreshStoresForMessage(
            client: client,
            data: data,
            notificationStore: notificationStore,
            sellerStore: sellerStore,
            sessionStore: sessionStore,
            messageStore: messageStore,
          );
        });

        FirebaseMessaging.onMessageOpenedApp.listen((message) {
          if (messageStore != null && sessionStore != null) {
            _handleNotificationClick(
              message,
              client: client,
              messageStore: messageStore,
              notificationStore: notificationStore,
              sessionStore: sessionStore,
            );
          }
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

      // Check if app was opened via notification when terminated
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null && messageStore != null && sessionStore != null) {
        _handleNotificationClick(
          initialMessage,
          client: client,
          messageStore: messageStore,
          notificationStore: notificationStore,
          sessionStore: sessionStore,
        );
      }
    } catch (e) {
      debugPrint('PushNotificationService.registerDevice failed: $e');
      // Push support is optional in local/dev builds.
    }
  }

  static Future<void> _handleNotificationClick(
    RemoteMessage message, {
    required ApiClient client,
    required MessageStore messageStore,
    required NotificationStore notificationStore,
    required UserSessionStore sessionStore,
  }) async {
    final targetId = message.data['targetId'] as String?;
    final type = message.data['type'] as String?;
    if (targetId == null || targetId.isEmpty) return;

    if (type == 'message') {
      // 1. Instantly mark read on backend and locally
      await messageStore.markRead(targetId, client: client);

      // 2. Fetch/refresh messages for this thread
      final userId = sessionStore.currentUser?.id ?? '';
      await messageStore.getOrFetchThread(
        threadId: targetId,
        client: client,
        userId: userId,
      );

      // 3. Navigate instantly using global navigator key
      UniMarketApp.navigatorKey.currentState?.push(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(threadId: targetId),
        ),
      );
    } else {
      final notification = AppNotification(
        id: message.messageId ?? 'fcm-${DateTime.now().millisecondsSinceEpoch}',
        title: message.notification?.title ?? 'UniMarket',
        body: message.notification?.body ?? '',
        timeLabel: 'Just now',
        section: 'Today',
        type: _typeFromData(type),
        targetId: targetId,
        actionLabel: _actionLabelFor(type),
      );
      final context = UniMarketApp.navigatorKey.currentContext;
      if (context != null) {
        await NotificationNavigation.open(context, notification);
      }
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

      // Sync from API for messages is removed to prevent race conditions during chat sessions.

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
