import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import 'skeleton_loaders.dart';

/// Renders a listing photo from a network URL or local asset path.
class ListingImage extends StatelessWidget {
  const ListingImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.cacheWidth,
  });

  final String source;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final int? cacheWidth;

  static bool isNetworkSource(String value) {
    final trimmed = value.trim().toLowerCase();
    return trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.contains('://');
  }

  /// placehold.co defaults to SVG; Android Flutter cannot decode that.
  static String normalizeSource(String value) {
    final trimmed = value.trim();
    if (!isNetworkSource(trimmed) || !trimmed.contains('placehold.co')) {
      return trimmed;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return trimmed;
    final segments = uri.pathSegments;
    if (segments.isEmpty) return trimmed;
    final last = segments.last.toLowerCase();
    if (last == 'png' ||
        last == 'jpg' ||
        last == 'jpeg' ||
        last == 'webp') {
      return trimmed;
    }
    final sizeSegment = segments.first;
    final normalizedPath = '/$sizeSegment/png';
    return uri.replace(path: normalizedPath).toString();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedSource = normalizeSource(source);
    final child = isNetworkSource(resolvedSource)
        ? _network(resolvedSource)
        : _asset(resolvedSource);

    return _wrap(child);
  }

  Widget _network(String url) {
    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      cacheWidth: cacheWidth,
      errorBuilder: (_, _, _) => _fallback(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SkeletonBox(
          width: width,
          height: height,
          borderRadius: borderRadius?.topLeft.x ?? 12,
        );
      },
    );
  }

  Widget _asset(String assetPath) {
    return Image.asset(
      assetPath,
      fit: fit,
      width: width,
      height: height,
      cacheWidth: cacheWidth,
      errorBuilder: (_, _, _) {
        if (isNetworkSource(source) || isNetworkSource(assetPath)) {
          return _network(normalizeSource(source));
        }
        return _fallback();
      },
    );
  }

  Widget _fallback() {
    return Image.asset(
      AppAssets.ob1Collage3,
      fit: fit,
      width: width,
      height: height,
      cacheWidth: cacheWidth,
    );
  }

  Widget _wrap(Widget child) {
    var result = child;
    if (width != null || height != null) {
      result = SizedBox(width: width, height: height, child: result);
    }
    if (borderRadius != null) {
      result = ClipRRect(borderRadius: borderRadius!, child: result);
    }
    return result;
  }
}
