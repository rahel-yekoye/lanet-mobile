// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // Colors
  static const primaryPurple = Color(0xFF8E44AD);
  static const lightPurple = Color(0xFFF3E5F5);
  static const darkGrey = Color(0xFF333333);
  static const mediumGrey = Color(0xFF666666);
  static const lightGrey = Color(0xFFEEEEEE);
  static const white = Colors.white;

  // Text Styles
  static const appBarTitleStyle = TextStyle(
    color: primaryPurple,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
  );

  static const characterStyle = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: darkGrey,
  );

  static const transliterationStyle = TextStyle(
    fontSize: 16,
    color: mediumGrey,
    fontWeight: FontWeight.w500,
  );

  static const vowelStyle = TextStyle(
    fontSize: 14,
    color: mediumGrey,
  );

  // Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryPurple,
      scaffoldBackgroundColor: white,
      appBarTheme: const AppBarTheme(
        backgroundColor: white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryPurple),
        titleTextStyle: appBarTitleStyle,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: lightPurple,
      ),
    );
  }
}