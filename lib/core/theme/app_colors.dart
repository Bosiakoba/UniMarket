import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const Color forestGreen = Color(0xFF093F0B);
  static const Color forestGreenLight = Color(0xFF0F5A14);
  static const Color forestGreenDeep = Color(0xFF062808);

  // Surfaces
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF0A0A0A);
  static const Color canvas = Color(0xFFF7F8F6);
  static const Color surfaceMuted = Color(0xFFF0F2EE);
  static const Color border = Color(0xFFE4E6E1);

  // Accents (from Figma)
  static const Color dustyRose = Color(0xFFCF9D9D);
  static const Color logoOrange = Color(0xFFFF8C42);
  static const Color logoPink = Color(0xFFFF4E63);
  static const Color dealRed = Color(0xFFE53935);
  static const Color verifiedGold = Color(0xFFE8B84A);

  // Text
  static const Color textPrimary = Color(0xFF0A0A0A);
  static const Color textSecondary = Color(0xFF5C6358);
  static const Color textTertiary = Color(0xFF8A9187);
  static const Color textOnGreen = Color(0xFFFFFFFF);

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [forestGreen, forestGreenLight, forestGreenDeep],
  );

  static const LinearGradient heroGlow = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x1AFFFFFF), Color(0x00FFFFFF)],
  );

  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [logoOrange, logoPink],
  );

  static const LinearGradient cardShine = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x08FFFFFF), Color(0x00FFFFFF)],
  );
}
