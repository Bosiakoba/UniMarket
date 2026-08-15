import '../config/api_config.dart';

/// Resolves listing photo URLs from the API (absolute R2 URLs or `/media/...` paths).
abstract final class MediaUrlResolver {
  static String resolve(String? source) {
    if (source == null || source.trim().isEmpty) return '';
    final trimmed = source.trim();
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/$'), '');
      return '$base$trimmed';
    }
    return trimmed;
  }

  static List<String> resolveAll(Iterable<String> sources) =>
      sources.map(resolve).where((url) => url.isNotEmpty).toList();
}
