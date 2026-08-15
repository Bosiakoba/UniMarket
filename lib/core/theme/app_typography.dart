import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static TextStyle display({Color color = AppColors.textOnGreen}) =>
      GoogleFonts.poppins(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        height: 1.1,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle h1({Color color = AppColors.textPrimary}) =>
      GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.3,
        color: color,
      );

  static TextStyle h2({Color color = AppColors.textPrimary}) =>
      GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.25,
        color: color,
      );

  static TextStyle h3({Color color = AppColors.textPrimary}) =>
      GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle body({Color color = AppColors.textSecondary}) =>
      GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: color,
      );

  static TextStyle bodyBold({Color color = AppColors.textPrimary}) =>
      GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle caption({Color color = AppColors.textTertiary}) =>
      GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle price({Color color = AppColors.forestGreen}) =>
      GoogleFonts.poppins(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle button({Color color = AppColors.white}) =>
      GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
      );
}
