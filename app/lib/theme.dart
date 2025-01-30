import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  // const greenColor = Color(0xFF1DB954);
  const greenColor = Colors.green;
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: greenColor,
      brightness: Brightness.dark, // Ensure a dark-themed palette
    ),
    useMaterial3: true,
    highlightColor: greenColor.withValues(alpha: 0.8), // Highlight color
    splashColor: greenColor.withValues(alpha: 0.4), // Custom ripple effect color
    appBarTheme: const AppBarTheme(
      backgroundColor: greenColor,
      foregroundColor: Colors.white, // Ensure high contrast text
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 20.0,
        color: Colors.white,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: greenColor,
        foregroundColor: Colors.white, // High contrast for text
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: greenColor,
      foregroundColor: Colors.white,
    ),
  );
}
