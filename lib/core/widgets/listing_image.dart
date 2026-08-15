import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../api/media_url.dart';
import '../models/post_listing_draft.dart';
import '../theme/app_colors.dart';
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
    if (!trimmed.contains('placehold.co')) {
      return trimmed;
    }
    // Swap placehold.co with a non-blocked alternative (picsum.photos)
    try {
      // Find size (e.g. 600 or 600x600)
      final sizePattern = RegExp(r'placehold\.co/(\d+)');
      final match = sizePattern.firstMatch(trimmed);
      final size = match != null ? match.group(1) : '600';
      
      // Find the text query parameter
      final textIndex = trimmed.indexOf('text=');
      if (textIndex != -1) {
        var text = trimmed.substring(textIndex + 5);
        // Clean up the text by decoding URL components
        text = Uri.decodeComponent(text);
        final id = (text.hashCode.abs() % 1000);
        return 'https://picsum.photos/id/$id/$size/$size';
      }
      return 'https://picsum.photos/$size';
    } catch (_) {
      return 'https://picsum.photos/600';
    }
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = MediaUrlResolver.resolve(source);
    if (trimmed.isEmpty) {
      return _wrap(_placeholder());
    }

    final resolvedSource = normalizeSource(trimmed);
    final Widget child;
    if (isNetworkSource(resolvedSource)) {
      child = _network(resolvedSource);
    } else if (PostListingDraft.isLocalFile(resolvedSource)) {
      child = Image.file(
        File(resolvedSource),
        fit: fit,
        width: width,
        height: height,
        cacheWidth: cacheWidth,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    } else {
      child = _asset(resolvedSource);
    }

    return _wrap(child);
  }

  Widget _network(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      maxWidthDiskCache: cacheWidth,
      maxHeightDiskCache: cacheWidth,
      placeholder: (context, _) => SkeletonBox(
        width: width,
        height: height,
        borderRadius: borderRadius?.topLeft.x ?? 12,
      ),
      errorWidget: (context, url, error) => _placeholder(),
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
        return _placeholder();
      },
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: AppColors.surfaceMuted,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.textTertiary,
          size: (width != null && height != null)
              ? (width! < height! ? width! : height!) * 0.28
              : 28,
        ),
      ),
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
