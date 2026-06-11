import 'dart:io';

import 'package:flutter/foundation.dart';

/// Home server API — override with:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.0.165:5080`
abstract final class ApiConfig {
  static const _defaultHost = '192.168.0.165';
  static const port = 5080;

  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    if (kIsWeb) {
      return 'http://$_defaultHost:$port';
    }

    if (Platform.isAndroid) {
      // Android emulator → host machine. Physical device → LAN IP.
      return 'http://$_defaultHost:$port';
    }

    if (Platform.isIOS) {
      return 'http://$_defaultHost:$port';
    }

    return 'http://$_defaultHost:$port';
  }
}
