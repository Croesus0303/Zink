import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette from Design Notes
  static const Color primaryColor = Color(0xFF8DD5F2);
  static const Color secondaryColor = Color(0xFFF2CB9B);
  static const Color tertiaryColor = Color(0xFFF25C05);
  static const Color errorColor = Color(0xFFF23005);
  static const Color darkErrorColor = Color(0xFF8C0303);

  // Additional Colors
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color surfaceColor = Colors.white;
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);

  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        error: errorColor,
        brightness: Brightness.light,
        surface: surfaceColor,
        background: backgroundColor,
      ),
      textTheme: GoogleFonts.interTextTheme(
        Theme.of(context).textTheme,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  static ThemeData darkTheme(BuildContext context) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        error: errorColor,
        brightness: Brightness.dark,
        surface: darkSurfaceColor,
        background: darkBackgroundColor,
      ),
      textTheme: GoogleFonts.interTextTheme(
        Theme.of(context).textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }
}
