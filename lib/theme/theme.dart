// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Paleta cálida etíope (beige, naranja, marrón)
  static const Color beigeBackground = Color(0xFFF5E8D4);
  static const Color creamCard = Color(0xFFFFF3E8);
  static const Color orangeAccent =
      Color(0xFFF97316); // naranja vivo pero cálido
  static const Color deepOrange = Color(0xFFDD6B20);
  static const Color brownText = Color(0xFF5D4037);
  static const Color darkBrown = Color(0xFF4E342E);

  // Text Styles
  static const TextStyle appBarTitleStyle = TextStyle(
    color: darkBrown,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.0,
    shadows: [
      Shadow(
        color: Colors.white70,
        offset: Offset(1, 1),
        blurRadius: 3,
      ),
    ],
  );

  static const TextStyle categoryTagStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle characterStyle = GoogleFonts.notoSansEthiopic(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: darkBrown,
  );

  static const TextStyle transliterationStyle = TextStyle(
    fontSize: 18,
    color: brownText,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle vowelStyle = TextStyle(
    fontSize: 16,
    color: deepOrange,
  );

  // Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: beigeBackground,
      primaryColor: orangeAccent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: darkBrown, size: 28),
        actionsIconTheme: IconThemeData(color: darkBrown),
        titleTextStyle: appBarTitleStyle,
      ),
      cardTheme: CardThemeData(
        color: creamCard,
        elevation: 6,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: darkBrown),
      ),
    );
  }
}
