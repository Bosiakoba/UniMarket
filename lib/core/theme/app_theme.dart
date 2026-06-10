import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final poppins = GoogleFonts.poppins();
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: poppins.fontFamily,
      fontFamilyFallback: poppins.fontFamilyFallback,
      scaffoldBackgroundColor: AppColors.canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.forestGreen,
        primary: AppColors.forestGreen,
        surface: AppColors.white,
      ),
    );

    final text = GoogleFonts.poppinsTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return base.copyWith(
      textTheme: text,
      primaryTextTheme: text,
      listTileTheme: ListTileThemeData(
        titleTextStyle: AppTypography.bodyBold(),
        subtitleTextStyle: AppTypography.caption(),
      ),
      snackBarTheme: SnackBarThemeData(
        contentTextStyle: AppTypography.body(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        labelStyle: AppTypography.caption(),
        secondaryLabelStyle: AppTypography.caption(color: AppColors.white),
      ),
      dialogTheme: DialogThemeData(
        titleTextStyle: AppTypography.h3(),
        contentTextStyle: AppTypography.body(),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTypography.h3(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 68,
        backgroundColor: AppColors.white,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(AppTypography.caption()),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          borderSide: const BorderSide(color: AppColors.forestGreen, width: 1.5),
        ),
        hintStyle: AppTypography.body(color: AppColors.textTertiary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          ),
          textStyle: AppTypography.button(),
        ),
      ),
    );
  }
}
