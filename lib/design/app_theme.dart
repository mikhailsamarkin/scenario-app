// Тема MaterialApp (SP-E9-01): кремовый фон контента, фиолетовый primary,
// терракотовый акцент. Экраны дополнительно используют явные стили
// AppColors/AppTypography (тёмный онбординг живёт вне ThemeData).

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Тема приложения Scenario.
abstract final class AppTheme {
  /// Светлая тема контентных экранов (home, сценарий, игра, группа).
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.headerPurple,
        primary: AppColors.headerPurple,
        secondary: AppColors.terracotta,
        surface: AppColors.bgCream,
      ),
      scaffoldBackgroundColor: AppColors.bgCream,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgCream,
        foregroundColor: AppColors.textOnLight,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.terracotta,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
