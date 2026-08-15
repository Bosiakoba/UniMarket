import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../api/api_client.dart';
import '../api/session_mode.dart';
import '../data/stores/message_store.dart';

/// Manages the SignalR connection to the backend ChatHub.
///
/// Provides real-time delivery of new messages so the chat screen
/// does not need to poll every second. Also handles:
/// - Automatic reconnect with exponential backoff
/// - Periodic heartbeats for online presence
/// - Presence change events from other users
class ChatSignalRService {
  HubConnection? _connection;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  bool _isConnected = false;
  bool _disposed = false;
  int _reconnectAttempts = 0;

  // Heartbeat every 30 seconds to keep presence alive.
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const int _maxReconnectAttempts = 12;
  static const Duration _maxReconnectDelay = Duration(seconds: 60);
  static const Duration _initialReconnectDelay = Duration(seconds: 2);

  /// Callback invoked when another user's presence changes.
  /// Receives ({userId, isOnline, lastSeenAt}).
  void Function(Map<String, dynamic> presence)? onPresenceChanged;

  bool get isConnected => _isConnected;

  /// Start the SignalR connection for the current user.
  ///
  /// Registers the [NewMessage] handler on the connection so that incoming
  /// messages are immediately applied to the [messageStore].
  Future<void> connect({
    required ApiClient client,
    required MessageStore messageStore,
    required String currentUserId,
    String? idToken,
  }) async {
    if (!isLiveSession(client)) return;
    if (_disposed) return;
    await disconnect();

    final baseUrl = client.baseUrl;

    try {
      _connection = HubConnectionBuilder()
          .withUrl(
            '$baseUrl/hubs/chat',
            options: HttpConnectionOptions(
              accessTokenFactory: () async => idToken ?? '',
              skipNegotiation: false,
            ),
          )
          .build();

      // ---- Register message handler on the live connection ----
      _connection!.on('NewMessage', (args) {
        if (args == null || args.isEmpty) return;
        final data = args[0] as Map<dynamic, dynamic>;
        messageStore.applyRealTimeMessage(
          data.cast<String, dynamic>(),
          currentUserId: currentUserId,
        );
      });

      _connection!.on('MessageEdited', (args) {
        if (args == null || args.isEmpty) return;
        final data = args[0] as Map<dynamic, dynamic>;
        final chatId = data['chatId'] as String?;
        final messageId = data['messageId'] as String?;
        final content = data['content'] as String?;
        if (chatId != null && messageId != null && content != null) {
          messageStore.applyMessageEdited(chatId, messageId, content);
        }
      });

      _connection!.on('MessageDeleted', (args) {
        if (args == null || args.isEmpty) return;
        final data = args[0] as Map<dynamic, dynamic>;
        final chatId = data['chatId'] as String?;
        final messageId = data['messageId'] as String?;
        if (chatId != null && messageId != null) {
          messageStore.applyMessageDeleted(chatId, messageId);
        }
      });

      // ---- Register presence change handler ----
      _connection!.on('UserPresenceChanged', (args) {
        if (args == null || args.isEmpty) return;
        final data = args[0] as Map<dynamic, dynamic>;
        final userId = data['userId'] as String?;
        final isOnline = data['isOnline'] as bool? ?? false;
        final lastSeenAt = data['lastSeenAt'] as String?;

        if (userId == null) return;

        debugPrint('[SignalR] Presence: $userId isOnline=$isOnline');

        // Update the message store's threads with presence info
        messageStore.applyPresenceUpdate(
          userId: userId,
          isOnline: isOnline,
          lastSeenAt: lastSeenAt != null ? DateTime.tryParse(lastSeenAt) : null,
        );

        // Notify external listeners (e.g., chat screen)
        onPresenceChanged?.call({
          'userId': userId,
          'isOnline': isOnline,
          'lastSeenAt': lastSeenAt,
        });
      });

      // ---- Connection lifecycle ----
      _connection!.onclose(({error}) {
        debugPrint('[SignalR] Connection closed: $error');
        _isConnected = false;
        _stopHeartbeat();
        _scheduleReconnect(client, messageStore, currentUserId, idToken);
      });

      await _connection!.start();
      _isConnected = true;
      _reconnectAttempts = 0;
      _startHeartbeat();
      debugPrint('[SignalR] Connected successfully');
    } catch (e) {
      debugPrint('[SignalR] Connection failed: $e');
      _isConnected = false;
      _scheduleReconnect(client, messageStore, currentUserId, idToken);
    }
  }

  /// Disconnect from the hub.
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempts = 0;
    _stopHeartbeat();
    if (_connection != null) {
      try {
        await _connection!.stop();
      } catch (_) {}
      _connection = null;
    }
    _isConnected = false;
  }

  /// Dispose — permanent teardown.
  Future<void> dispose() async {
    _disposed = true;
    await disconnect();
  }

  // ---- Heartbeat ----

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) async {
      if (!_isConnected || _disposed) return;
      try {
        await _connection?.invoke('SendHeartbeat');
      } catch (_) {
        // Connection might have dropped — reconnection will handle it.
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // ---- Reconnect ----

  void _scheduleReconnect(
    ApiClient client,
    MessageStore messageStore,
    String currentUserId,
    String? idToken,
  ) {
    if (_disposed) return;
    _reconnectAttempts++;
    if (_reconnectAttempts > _maxReconnectAttempts) {
      debugPrint('[SignalR] Max reconnect attempts reached. Giving up.');
      return;
    }
    // Exponential backoff: 2s, 4s, 8s, 16s, 32s, then cap at 60s
    final delay = Duration(
      milliseconds: (_initialReconnectDelay.inMilliseconds *
              (1 << (_reconnectAttempts - 1)))
          .clamp(
        _initialReconnectDelay.inMilliseconds,
        _maxReconnectDelay.inMilliseconds,
      ),
    );
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (!_disposed) {
        connect(
          client: client,
          messageStore: messageStore,
          currentUserId: currentUserId,
          idToken: idToken,
        ).catchError((_) {});
      }
    });
  }
}
