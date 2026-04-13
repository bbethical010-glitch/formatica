import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand & Accent Palette
  static const Color primaryIndigo = Color(0xFF5B4FE8);
  static const Color primaryLight = Color(0xFFC4C0FF);
  static const Color audioRose = Color(0xFFE8507C);
  static const Color videoPurple = Color(0xFF8B5CF6);
  static const Color compressOrange = Color(0xFFF97316);
  static const Color imageCyan = Color(0xFF06B6D4);
  static const Color docIndigo = Color(0xFF6366F1);
  static const Color mergeTeal = Color(0xFF10B981);
  static const Color splitAmber = Color(0xFFF59E0B);
  static const Color tertiary = Color(0xFF4CD7F6);
  static const Color greySlate = Color(0xFF64748B);
  static const Color error = Color(0xFFFFB4AB);

  // Dark Theme Surfaces (The Void)
  static const Color darkBg = Color(0xFF0B1326);
  static const Color darkSurface = Color(0xFF171F33);
  static const Color darkSurfaceLow = Color(0xFF131B2E);
  static const Color darkSurfaceHigh = Color(0xFF222A3D);
  static const Color darkSurfaceHighest = Color(0xFF2D3449);
  static const Color darkTextPrimary = Color(0xFFDAE2FD);
  static const Color darkTextSecondary = Color(0xFFC8C4D8);
  static const Color darkOutline = Color(0xFF918FA1);
  static const Color darkOutlineVar = Color(0xFF464555);

  // Light Theme Surfaces (The Prism)
  static const Color lightBg = Color(0xFFF8F9FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1E293B);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightOutline = Color(0xFFCBD5E1);

  // Glass Specs
  static const Color darkGlassBg = Color(0x12FFFFFF); // 7% white
  static const Color lightGlassBg = Color(0xD1FFFFFF); // 82% white
  static const Color specularHighlight = Color(0x33FFFFFF); // 20% white
}

class AppTextStyles {
  // Manrope Editorial Hierarchy
  static TextStyle displayLarge = GoogleFonts.manrope(
    fontSize: 56,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.5,
  );

  static TextStyle headlineSmall = GoogleFonts.manrope(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle bodyMedium = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle studioLabel = GoogleFonts.manrope(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.4,
    color: AppColors.primaryIndigo,
  );
  
  static TextStyle badge = GoogleFonts.manrope(
    fontSize: 9,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.0,
  );
}

class AppTheme {
  static ThemeData darkTheme() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryIndigo,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        outline: AppColors.darkOutline,
        error: AppColors.error,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).apply(
        bodyColor: AppColors.darkTextPrimary,
        displayColor: AppColors.darkTextPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headlineSmall.copyWith(color: AppColors.darkTextPrimary),
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData lightTheme() {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryIndigo,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        outline: AppColors.lightOutline,
        error: AppColors.error,
      ),
    );
    
    return base.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).apply(
        bodyColor: AppColors.lightTextPrimary,
        displayColor: AppColors.lightTextPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headlineSmall.copyWith(color: AppColors.lightTextPrimary),
        iconTheme: const IconThemeData(color: AppColors.lightTextPrimary),
      ),
    );
  }
}
