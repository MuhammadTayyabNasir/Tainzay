// lib/app/config/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- THEME DEFINITION ---
// This file centralizes all the visual styling for the application,
// making it easy to maintain a consistent look and feel or to add new themes.

class AppTheme {
  // --- Green Light Theme Palette ---
  static const Color _primaryGreen = Color(0xFF2E8B57); // SeaGreen
  static const Color _secondaryGreen = Color(0xFF66CDAA); // MediumAquamarine
  static const Color _lightBackground = Color(0xFFF4F6F5); // Very light greyish-green
  static const Color _lightSurface = Colors.white;
  static const Color _lightText = Color(0xFF333333);
  static const Color _lightBorder = Color(0xFFDDE2E1);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: _primaryGreen,
    scaffoldBackgroundColor: _lightBackground,

    colorScheme: const ColorScheme.light(
        primary: _primaryGreen,
        secondary: _secondaryGreen,
        background: _lightBackground,
        surface: _lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onBackground: _lightText,
        onSurface: _lightText,
        error: Colors.redAccent,
        onError: Colors.white
    ),

    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
      bodyLarge: const TextStyle(color: _lightText),
      bodyMedium: TextStyle(color: _lightText.withOpacity(0.7)),
      headlineLarge: const TextStyle(fontWeight: FontWeight.w700, color: _primaryGreen),
      headlineMedium: const TextStyle(fontWeight: FontWeight.w600, color: _lightText),
      headlineSmall: const TextStyle(fontWeight: FontWeight.w600),
      titleLarge: const TextStyle(fontWeight: FontWeight.bold),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: _lightSurface,
      foregroundColor: _lightText,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: _lightText),
    ),

    cardTheme: CardThemeData(
      elevation: 0,
      color: _lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: const BorderSide(color: _lightBorder, width: 1),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _lightSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: _lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: _lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
        borderSide: const BorderSide(color: _primaryGreen, width: 1.5),
      ),
      labelStyle: TextStyle(color: _lightText.withOpacity(0.8)),
      hintStyle: TextStyle(color: _lightText.withOpacity(0.5)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        elevation: 2,
        shadowColor: _primaryGreen.withOpacity(0.3),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        )
    ),

    listTileTheme: ListTileThemeData(
      selectedColor: _primaryGreen,
      selectedTileColor: _primaryGreen.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),

    iconTheme: IconThemeData(color: _lightText.withOpacity(0.8)),
    dividerTheme: const DividerThemeData(color: _lightBorder, thickness: 1),
  );
}