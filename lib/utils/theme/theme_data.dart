import 'package:flutter/material.dart';

final ThemeData kThemeData = ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  focusColor: const Color(0xFF5B7EFF),
  // fontFamily: GoogleFonts.inter().fontFamily,
  colorScheme: ColorScheme.light(
    primary: const Color(0xFFB8E986), // Soft mint green
    secondary: const Color(0xFF5B7EFF), // Vibrant blue
    surface: const Color(0xFFFFFFFF), // Pure white for cards
    error: const Color(0xFFFF7F7F), // Coral
    onPrimary: const Color(0xFF2C2C2C), // Dark text on mint
    onSecondary: const Color(0xFFFFFFFF), // White text on blue
    onSurface: const Color(0xFF2C2C2C), // Dark text on surface
    onError: const Color(0xFFFFFFFF), // White text on error
  ),
  scaffoldBackgroundColor:
      Colors.transparent, // Transparent for gradient background
  cardTheme: const CardThemeData(
    color: Color(0xFFFFFFFF), // Pure white cards
    elevation: 2,
    shadowColor: Colors.black12,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent, // Transparent to show gradient
    foregroundColor: Color(0xFF2C2C2C), // Dark text
    elevation: 0,
    surfaceTintColor: Colors.transparent,
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Color(0xFF2C2C2C)),
    displayMedium: TextStyle(color: Color(0xFF2C2C2C)),
    displaySmall: TextStyle(color: Color(0xFF2C2C2C)),
    headlineLarge: TextStyle(color: Color(0xFF2C2C2C)),
    headlineMedium: TextStyle(color: Color(0xFF2C2C2C)),
    headlineSmall: TextStyle(color: Color(0xFF2C2C2C)),
    titleLarge: TextStyle(color: Color(0xFF2C2C2C)),
    titleMedium: TextStyle(color: Color(0xFF2C2C2C)),
    titleSmall: TextStyle(color: Color(0xFF2C2C2C)),
    bodyLarge: TextStyle(color: Color(0xFF2C2C2C)),
    bodyMedium: TextStyle(color: Color(0xFF2C2C2C)),
    bodySmall: TextStyle(color: Color(0xFF6B7280)),
    labelLarge: TextStyle(color: Color(0xFF2C2C2C)),
    labelMedium: TextStyle(color: Color(0xFF6B7280)),
    labelSmall: TextStyle(color: Color(0xFF6B7280)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFFFFFFF), // Pure white fill
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF5B7EFF), width: 2),
    ),
    labelStyle: const TextStyle(color: Color(0xFF6B7280)),
    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
  ),
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: const Color(0xFF5B7EFF), // Blue cursor
    selectionColor: const Color(
      0xFF5B7EFF,
    ).withValues(alpha: 0.3), // Light blue selection background
    selectionHandleColor: const Color(0xFF5B7EFF), // Blue selection handles
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFB8E986), // Mint green
      foregroundColor: const Color(0xFF2C2C2C), // Dark text
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.1),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(foregroundColor: const Color(0xFF5B7EFF)),
  ),
  iconTheme: const IconThemeData(color: Color(0xFF2C2C2C)),
);
