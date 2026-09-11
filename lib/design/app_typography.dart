// Типографика приложения (SP-E9-01) по docs/figma/design-tokens.md.
//
// Заголовки — Playfair Display (OFL, assets/fonts); текст — системный
// шрифт платформы. При ревизии гарнитуры из Figma меняется константа
// [displayFontFamily].

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Типографика дизайн-системы Scenario.
abstract final class AppTypography {
  /// Семейство заголовков (serif по макетам).
  static const String displayFontFamily = 'PlayfairDisplay';

  /// Логотип «Scenario» в шапке home.
  static const TextStyle logo = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnDark,
  );

  /// Крупный заголовок экрана на тёмном («Что сегодня?»).
  static const TextStyle displayOnDark = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnDark,
  );

  /// Подзаголовок шапки home.
  static const TextStyle subtitleOnDark = TextStyle(
    fontSize: 16,
    color: AppColors.textMutedOnDark,
  );

  /// Крупный заголовок на светлом фоне (название сценария/игры).
  static const TextStyle displayOnLight = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnLight,
  );

  /// Заголовок hero поверх фото (название сценария).
  static const TextStyle displayOnPhoto = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnDark,
  );

  /// Заголовок шага онбординга.
  static const TextStyle onboardingTitle = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnDark,
    height: 1.25,
  );

  /// Подтекст шага онбординга.
  static const TextStyle onboardingBody = TextStyle(
    fontSize: 16,
    height: 1.45,
    color: AppColors.textMutedOnDark,
  );

  /// Капс-надзаголовок (терракотовый на тёмном, тёмный на светлом).
  static TextStyle caps({Color color = AppColors.terracotta}) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.2,
        color: color,
      );

  /// Подтекст на светлом фоне.
  static const TextStyle bodyOnLight = TextStyle(
    fontSize: 16,
    height: 1.45,
    color: AppColors.textOnLight,
  );

  /// Интро сценария (курсивный serif).
  static const TextStyle scenarioIntro = TextStyle(
    fontFamily: displayFontFamily,
    fontSize: 20,
    fontStyle: FontStyle.italic,
    height: 1.4,
    color: AppColors.textOnLight,
  );

  /// Название на карточке поверх фото.
  static const TextStyle cardTitleOnPhoto = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnDark,
    height: 1.2,
  );

  /// Подпись категории на карточке поверх фото (капс).
  static TextStyle cardCategoryOnPhoto = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.8,
    color: AppColors.terracotta,
  );

  /// Название на светло-лавандовой карточке.
  static const TextStyle cardTitleOnLight = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnLight,
  );
}
