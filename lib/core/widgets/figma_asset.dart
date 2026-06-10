import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Loads a Figma-exported asset whether it is PNG or SVG.
class FigmaAsset extends StatelessWidget {
  const FigmaAsset({
    super.key,
    required this.path,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.color,
  });

  final String path;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (path.endsWith('.svg')) {
      return SvgPicture.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        colorFilter: color != null
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : null,
      );
    }
    return Image.asset(path, width: width, height: height, fit: fit);
  }
}
