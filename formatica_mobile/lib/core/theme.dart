import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Brand - Prototype Palette
  static const Color bg = Color(0xFF0B1326);
  static const Color surface = Color(0xFF171F33);
  static const Color surfaceLow = Color(0xFF131B2E);
  static const Color surfaceHigh = Color(0xFF222A3D);
  static const Color surfaceHighest = Color(0xFF2D3449);
  
  static const Color primary = Color(0xFFC4C0FF);
  static const Color primaryContainer = Color(0xFF5B4FE8);
  static const Color secondary = Color(0xFFD0BCFF);
  static const Color tertiary = Color(0xFF4CD7F6);
  
  static const Color onSurface = Color(0xFFDAE2FD);
  static const Color onSurfaceVar = Color(0xFFC8C4D8);
  static const Color outline = Color(0xFF918FA1);
  static const Color outlineVar = Color(0xFF464555);
  
  // Tool Specific
  static const Color audioRose = Color(0xFFE8507C);
  static const Color audioViolet = Color(0xFFAA5CF6);
  static const Color videoPurple = Color(0xFF8B5CF6);
  static const Color compressOrange = Color(0xFFF97316);
  static const Color mergeTeal = Color(0xFF10B981);
  static const Color splitAmber = Color(0xFFF59E0B);
  static const Color docIndigo = Color(0xFF6366F1);
  static const Color imageCyan = Color(0xFF22D3EE);
  static const Color greySlate = Color(0xFF64748B);
  static const Color error = Color(0xFFFFB4AB);
  static const Color darkTextPrimary = Color(0xFFDAE2FD);
  static const Color darkTextSecondary = Color(0xFFC8C4D8);

  // Mesh Gradients
  static const Color meshIndigo = Color(0xFF1A1B3A);
  static const Color meshPurple = Color(0xFF2D1633);
  static const Color meshNavy = Color(0xFF0F1628);

  // Borders & Dividers
  static const Color dividerWhite = Color(0x0FFFFFFF); // rgba(255,255,255,0.06)
  static const Color ghostBorder = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color ghostBorderStrong = Color(0x1EFFFFFF); // rgba(255,255,255,0.12)

  // Light Mode Equivalents
  static const Color lightBg = Color(0xFFF8F9FF);
  static const Color lightText = Color(0xFF1E293B);
  static const Color lightTextMuted = Color(0xFF64748B);

  // Glass Specs
  static const Color glassBorder = Color(0x2BFFFFFF); // rgba(255, 255, 255, 0.17)
  static const Color white = Color(0xFFFFFFFF);
}

class AppTextStyles {
  // Manrope Editorial Hierarchy
  static TextStyle displayLarge = GoogleFonts.manrope(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: -1.0,
  );

  static TextStyle headlineSmall = GoogleFonts.manrope(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
  );

  static TextStyle bodyMedium = GoogleFonts.manrope(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static TextStyle studioLabel = GoogleFonts.manrope(
    fontSize: 10,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.5,
    color: AppColors.onSurfaceVar.withOpacity(0.6),
  );
}

class AppTheme {
  static ThemeData darkTheme() {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.bg,
        primaryContainer: AppColors.primaryContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceVar,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVar,
        error: AppColors.error,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).apply(
        bodyColor: AppColors.onSurface,
        displayColor: AppColors.onSurface,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.glassBorder, width: 0.8),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.headlineSmall.copyWith(color: AppColors.onSurface),
        iconTheme: const IconThemeData(color: AppColors.onSurface),
      ),
    );
  }

  static ThemeData lightTheme() {
    final base = ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.lightBg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryContainer,
        surface: Colors.white,
        onSurface: AppColors.lightText,
      ),
    );
    
    return base.copyWith(
      textTheme: GoogleFonts.manropeTextTheme(base.textTheme).apply(
        bodyColor: AppColors.lightText,
        displayColor: AppColors.lightText,
      ),
    );
  }
}








