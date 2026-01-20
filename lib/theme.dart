import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // <--- Import this

class AppTheme {
  // 1. CORE PALETTE
  static const Color electricBlue = Color(0xFF2979FF);
  static const Color deepViolet = Color(0xFF6200EA); // Darker shade for gradients

  // A gradient to use on buttons/cards
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [electricBlue, deepViolet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Color facebookBlue = Color(0xFF1877F2);
  static const Color goldAccent = Color(0xFFFFC107);
  static const Color errorRed = Color(0xFFE53935);

  // 2. COLOR SCHEMES
  // Use a very subtle blue-tinted grey for the background, not plain grey
  static const Color _lightBackground = Color(0xFFF0F3F8);
  static const Color _lightSurface = Colors.white;
  static final Color _lightShadow = const Color(0xFF2979FF).withOpacity(0.07); // Blue-tinted shadow

  static const Color _darkBackground = Color(0xFF0A0E17); // Deep blue-black
  static const Color _darkSurface = Color(0xFF161B26);
  static final Color _darkShadow = Colors.black.withOpacity(0.5);

  // 3. THEME CONFIGURATION
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: _lightBackground,
    shadowColor: _lightShadow, // Use our blue-tinted shadow

    // --- TYPOGRAPHY UPGRADE ---
    textTheme: GoogleFonts.poppinsTextTheme(), // Applies Poppins everywhere

    colorScheme: ColorScheme.fromSeed(
      seedColor: electricBlue,
      brightness: Brightness.light,
      primary: electricBlue,
      surface: _lightSurface,
      surfaceContainerHighest: const Color(0xFFE8EBF2),
    ),

    cardTheme: const CardThemeData(
      color: _lightSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)), // Softer corners
      ),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _darkBackground,
    shadowColor: _darkShadow,

    // --- TYPOGRAPHY UPGRADE ---
    textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),

    colorScheme: ColorScheme.fromSeed(
      seedColor: electricBlue,
      brightness: Brightness.dark,
      primary: electricBlue,
      surface: _darkSurface,
      surfaceContainerHighest: const Color(0xFF222834),
    ),

    cardTheme: const CardThemeData(
      color: _darkSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
  );
}