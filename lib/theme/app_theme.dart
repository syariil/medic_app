import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ─── COLORS ─────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1A56DB);
  static const Color primaryDark = Color(0xFF1E3A5F);
  static const Color accent = Color(0xFF00C9A7);

  static const Color sidebarStart = Color(0xFF1A2238);
  static const Color sidebarEnd = Color(0xFF2D4A7A);

  static const Color bgStart = Color(0xFFF0F4FF);
  static const Color bgEnd = Color(0xFFE8EFF9);

  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF1A2238);
  static const Color textSecondary = Color(0xFF6B7A99);

  static const List<Color> chartColors = [
    Color(0xFF1A56DB),
    Color(0xFF00C9A7),
    Color(0xFFFF6B6B),
    Color(0xFFFFB347),
    Color(0xFF9B59B6),
    Color(0xFF3498DB),
  ];

  // ─── GRADIENTS ───────────────────────────────────────────────────────────────
  static const LinearGradient sidebarGradient = LinearGradient(
    colors: [sidebarStart, sidebarEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient appBarGradient = LinearGradient(
    colors: [primary, Color(0xFF6366F1)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [bgStart, bgEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── SHADOWS ─────────────────────────────────────────────────────────────────
  static final List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // ─── THEME DATA ──────────────────────────────────────────────────────────────
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: primary,
      fontFamily: 'Nunito',
      scaffoldBackgroundColor: bgStart,
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
