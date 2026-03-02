import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();
  static const primary = Color(0xFFD42B2B);
  static const primaryDark = Color(0xFFB31212);
  static const gold = Color(0xFFFFD700);
  static const warmCream = Color(0xFFFFF9E3);
  static const brownDeep = Color(0xFF4A2B10);
  static const brownMid = Color(0xFF7D5A3E);
  static const brownLight = Color(0xFF8B7E66);
  static const borderColor = Color(0xFFD4C3A1);
  static const toggleBg = Color(0xFFEBDDB8);
  static const success = Color(0xFF2E7D32);
  static const error = Color(0xFFD32F2F);

  static const festiveGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );
}

class AppTheme {
  AppTheme._();
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    scaffoldBackgroundColor: AppColors.warmCream,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      hintStyle: const TextStyle(color: AppColors.brownLight, fontSize: 14),
    ),
  );
}
