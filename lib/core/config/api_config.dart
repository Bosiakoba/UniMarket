import 'package:flutter/foundation.dart';

/// API base URL — override at build/run time:
/// `flutter build apk --dart-define=API_BASE_URL=https://unimarket-production-184e.up.railway.app`
abstract final class ApiConfig {
  static const productionUrl =
      'https://unimarket-production-184e.up.railway.app';
  static const port = 5080;

  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    // Common mistake: backend env var name passed to Flutter.
    const legacyOverride = String.fromEnvironment('Api__PublicBaseUrl');
    if (legacyOverride.isNotEmpty) return legacyOverride;

    if (kReleaseMode) return productionUrl;

    // Use production backend for local development as well
    return productionUrl;
  }
}
