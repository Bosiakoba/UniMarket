import 'package:flutter/material.dart';

/// Constrains layout to phone width on desktop/web only.
class MobileViewport extends StatelessWidget {
  const MobileViewport({super.key, required this.child});

  final Widget child;

  static const double designWidth = 430;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= designWidth + 40) return child;

    return ColoredBox(
      color: const Color(0xFF0E0E0E),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: designWidth),
            child: child,
          ),
        ),
      ),
    );
  }
}
