import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand - Ethereal Prism Palette
  static const Color primaryIndigo = Color(0xFF5B4FE8);
  static const Color audioRose = Color(0xFFE8507C);
  static const Color videoPurple = Color(0xFF8B5CF6);
  static const Color compressOrange = Color(0xFFF97316);
  static const Color imageCyan = Color(0xFF06B6D4);

  // Dark theme surfaces (The Void)
  static const Color darkBg = Color(0xFF0B1326);
  static const Color darkSurface = Color(0xFF0B1326);
  static const Color darkSurfaceCard = Color(0xFF171F33);
  static const Color darkSurfaceBright = Color(0xFF31394D);
  static const Color darkTextPrimary = Color(0xFFDAE2FD);
  static const Color darkTextSecondary = Color(0xFFC8C4D8);
  static const Color darkOutline = Color(0xFF464555);

  // Glass Specs
  static const Color darkGlassBg = Color(0x12FFFFFF); // rgba(255, 255, 255, 0.07) approximated
  static const Color lightGlassBg = Color(0xBFFFFFFF); // rgba(255, 255, 255, 0.75)
  static const Color specularHighlight = Color(0x33FFFFFF); // white at 20%
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
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.4,
    color: AppColors.primaryIndigo,
  );
}

class AppTheme {
  static ThemeData darkTheme() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.darkBg,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryIndigo,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        surfaceVariant: AppColors.darkSurfaceCard,
        outlineVariant: AppColors.darkOutline.withOpacity(0.15),
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).apply(
        bodyColor: AppColors.darkTextPrimary,
        displayColor: AppColors.darkTextPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none, // The "No-Line" Rule
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headlineSmall.copyWith(color: AppColors.darkTextPrimary),
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryIndigo,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.darkOutline.withOpacity(0.15),
        thickness: 0.5,
      ),
    );
  }

  static ThemeData lightTheme() {
    // Keep light theme for fallback, but focus on Liquid Glass (usually Dark/Ambient)
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF8F9FF),
    );
    
    return base.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme),
    );
  }
}








