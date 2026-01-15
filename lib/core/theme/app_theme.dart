import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(AppColors.primaryColor),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(AppColors.lightBackgroundColor),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(AppColors.backgroundColor),
        foregroundColor: Color(AppColors.textPrimary),
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: Color(AppColors.lightSurfaceColor),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSizes.borderRadius)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(AppColors.primaryColor),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(AppColors.backgroundColor),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(AppColors.backgroundColor),
        foregroundColor: Color(AppColors.textPrimary),
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(
        color: Color(AppColors.surfaceColor),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppSizes.borderRadiusLarge)),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: Color(AppColors.textPrimary), fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(color: Color(AppColors.textPrimary), fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(color: Color(AppColors.textPrimary), fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(color: Color(AppColors.textPrimary)),
        bodyMedium: TextStyle(color: Color(AppColors.textSecondary)),
        bodySmall: TextStyle(color: Color(AppColors.textSecondary)),
      ),
    );
  }
}
