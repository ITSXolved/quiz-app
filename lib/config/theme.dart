import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Islamic-inspired emerald palette
  static const Color primaryDark = Color(0xFF0D1B2A);
  static const Color primaryMid = Color(0xFF1B3A4B);
  static const Color accent = Color(0xFF00C9A7);
  static const Color accentGold = Color(0xFFF0C27E);
  static const Color surface = Color(0xFF152238);
  static const Color surfaceLight = Color(0xFF1E3050);
  static const Color textPrimary = Color(0xFFE8F1F5);
  static const Color textSecondary = Color(0xFF8BA4B8);
  static const Color success = Color(0xFF4ADE80);
  static const Color error = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFFD93D);
  static const Color cardBg = Color(0xFF1A2D42);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryDark,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: accentGold,
        surface: surface,
        error: error,
        onPrimary: primaryDark,
        onSecondary: primaryDark,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineLarge: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 15,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textSecondary.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: GoogleFonts.poppins(color: textSecondary),
        labelStyle: GoogleFonts.poppins(color: textSecondary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: primaryMid,
        selectedItemColor: accent,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: primaryDark,
      ),
      dividerTheme: DividerThemeData(
        color: textSecondary.withValues(alpha: 0.15),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        labelStyle: GoogleFonts.poppins(color: textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
