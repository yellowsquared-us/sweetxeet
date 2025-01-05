import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: Brightness.light,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400),
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: Brightness.dark,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w400),
        displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w400),
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w400),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w400),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}