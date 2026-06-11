import 'package:flutter/material.dart';

import '../constants/app_assets.dart';

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

  static bool isNetworkSource(String value) =>
      value.startsWith('http://') || value.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final child = isNetworkSource(source)
        ? Image.network(
            source,
            fit: fit,
            width: width,
            height: height,
            cacheWidth: cacheWidth,
            errorBuilder: (_, __, ___) => _fallback(),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                width: width,
                height: height,
                color: Colors.grey.shade200,
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
          )
        : Image.asset(
            source,
            fit: fit,
            width: width,
            height: height,
            cacheWidth: cacheWidth,
            errorBuilder: (_, __, ___) => _fallback(),
          );

    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
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
}
