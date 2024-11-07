import 'package:flutter/material.dart';
import 'package:ptuddnt/core/constants/colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      visualDensity: VisualDensity.adaptivePlatformDensity,
      primarySwatch: const MaterialColor(
        0xFFC02135,
        {
          50: Color(0xFFF5D0D4),
          100: Color(0xFFE799A0),
          200: Color(0xFFD7626C),
          300: Color(0xFFC02135),
          400: Color(0xFF9F1F31),
          500: Color(0xFF7E1C2D),
          600: Color(0xFF5E1826),
          700: Color(0xFF461425),
          800: Color(0xFF2E0F1D),
          900: Color(0xFF160A14),
        },
      ),
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: Colors.white,
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: const TextStyle(color: Color(0xffcccccc)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(color: AppColors.primary50),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30.0),
          borderSide: const BorderSide(color: Color(0xffffffff)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16.0),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary
        )
      )
    );
  }
}
