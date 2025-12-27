import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 1. Private color palette (Single Source of Truth)
class _AppColors {
  // Brand Colors
  static const primaryBlue = Color(0xFF2563EB); // Royal Blue
  static const secondaryTeal = Color(0xFF14B8A6); // Teal Mint

  // Backgrounds
  static const bgLight = Color(0xFFF8FAFC); // Cool Slate White
  static const bgDark = Color(0xFF0F172A); // Deep Slate Navy

  // Surfaces
  static const surfaceLight = Colors.white;
  static const surfaceDark = Color(0xFF1E293B);

  // Text
  static const textDark = Color(0xFF0F172A); // Slate 900
  static const textLight = Color(0xFFFFFFFF); // Pure White

  // Secondary Text (Subtitles, hints)
  static const textGreyLight = Color(0xFF334155); // Slate 700
  static const textGreyDark = Color(0xFFE2E8FF); // Slate 100

  // Borders
  static const borderLight = Color(0xFFE2E8FF); // Slate 100
  static const borderDark = Color(0xFF334155); // Slate 700
}

class AppTheme {
  AppTheme._();

  // --- LIGHT THEME ---
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: _AppColors.bgLight,
    dividerColor: _AppColors.borderLight,
    fontFamily: GoogleFonts.roboto().fontFamily,

    // Color Scheme
    colorScheme: ColorScheme.fromSeed(
      seedColor: _AppColors.primaryBlue,
      primary: _AppColors.primaryBlue,
      secondary: _AppColors.secondaryTeal,
      surface: _AppColors.surfaceLight,
      onSurface: _AppColors.textDark,
      onSurfaceVariant: _AppColors.textGreyLight,
      outline: _AppColors.borderLight,
      brightness: Brightness.light,
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: _AppColors.surfaceLight,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _AppColors.borderLight),
      ),
    ),

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: _AppColors.textDark),
      titleTextStyle: GoogleFonts.poppins(
        color: _AppColors.textDark,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _AppColors.surfaceLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _AppColors.primaryBlue, width: 2),
      ),
      hintStyle: GoogleFonts.roboto(color: _AppColors.textGreyLight),
      labelStyle: GoogleFonts.roboto(color: _AppColors.textGreyLight),
    ),

    // Text Theme (Poppins for Headings, Roboto for Body)
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: _AppColors.textDark,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: _AppColors.textDark,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: _AppColors.textDark,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: _AppColors.textDark,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _AppColors.textDark,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _AppColors.textDark,
      ),
      bodyLarge: GoogleFonts.roboto(fontSize: 16, color: _AppColors.textDark),
      bodyMedium: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: _AppColors.textGreyLight,
      ),
    ),
  );

  // --- DARK THEME ---
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _AppColors.bgDark,
    dividerColor: _AppColors.borderDark,
    fontFamily: GoogleFonts.roboto().fontFamily,

    // Color Scheme
    colorScheme: ColorScheme.fromSeed(
      seedColor: _AppColors.primaryBlue,
      primary: _AppColors.primaryBlue,
      secondary: _AppColors.secondaryTeal,
      surface: _AppColors.surfaceDark,
      onSurface: _AppColors.textLight,
      onSurfaceVariant: _AppColors.textGreyDark,
      outline: _AppColors.borderDark,
      brightness: Brightness.dark,
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: _AppColors.surfaceDark,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _AppColors.borderDark),
      ),
    ),

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: _AppColors.textLight),
      titleTextStyle: GoogleFonts.poppins(
        color: _AppColors.textLight,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _AppColors.primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _AppColors.surfaceDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _AppColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _AppColors.secondaryTeal, width: 2),
      ),
      hintStyle: GoogleFonts.roboto(color: _AppColors.textGreyDark),
      labelStyle: GoogleFonts.roboto(color: _AppColors.textGreyDark),
    ),

    // Text Theme (Montserrat for Headings, Roboto for Body)
    textTheme: TextTheme(
      displayLarge: GoogleFonts.montserrat(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: _AppColors.textLight,
      ),
      headlineMedium: GoogleFonts.montserrat(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: _AppColors.textLight,
      ),
      headlineSmall: GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: _AppColors.textLight,
      ),
      titleLarge: GoogleFonts.montserrat(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: _AppColors.textLight,
      ),
      titleMedium: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _AppColors.textLight,
      ),
      titleSmall: GoogleFonts.montserrat(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _AppColors.textLight,
      ),
      bodyLarge: GoogleFonts.roboto(fontSize: 16, color: _AppColors.textLight),
      bodyMedium: GoogleFonts.roboto(
        fontSize: 14,
        color: _AppColors.textGreyDark,
      ),
    ),
  );
}
