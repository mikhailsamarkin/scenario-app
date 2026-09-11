// Палитра приложения (SP-E9-01) по docs/figma/design-tokens.md.
//
// Значения — приближения по скриншотам макетов; при ревизии из Figma
// Dev Mode меняются только константы здесь.

import 'package:flutter/material.dart';

/// Цвета дизайн-системы Scenario.
abstract final class AppColors {
  /// Фон онбординга (тёмный баклажановый).
  static const Color bgDark = Color(0xFF2B2433);

  /// Основная полоса шапки home (тёмно-фиолетовый).
  static const Color headerPurple = Color(0xFF5F2B4E);

  /// Тонкая верхняя полоса шапки home (тёмно-бордовый).
  static const Color headerPlum = Color(0xFF46203C);

  /// Фон контентных экранов (кремовый).
  static const Color bgCream = Color(0xFFF6F0E6);

  /// Альтернативная полоса контента (чередование секций).
  static const Color bgCreamAlt = Color(0xFFEFE7D9);

  /// Акцент (терракотовый): капс-надзаголовки, основные кнопки, активные
  /// точки.
  static const Color terracotta = Color(0xFFC4785B);

  /// Светло-лавандовые карточки (список игр, характеристики 2×2).
  static const Color cardLavender = Color(0xFFECE4F2);

  /// Чипсы на лавандовой карточке (чуть темнее карточки).
  static const Color chipLavender = Color(0xFFDFD4EC);

  /// Тёмная вторичная кнопка («Начать без уведомлений»).
  static const Color buttonDark = Color(0xFF4A4153);

  /// Текст на тёмном фоне.
  static const Color textOnDark = Color(0xFFF4EFEA);

  /// Приглушённый текст на тёмном фоне.
  static const Color textMutedOnDark = Color(0xFFB5AABA);

  /// Основной текст на светлом фоне.
  static const Color textOnLight = Color(0xFF2B2433);

  /// Приглушённый текст на светлом фоне (подписи характеристик).
  static const Color textMutedOnLight = Color(0xFF7C6E85);

  /// Затемнение под текстом на фото (градиент hero-блоков).
  static const List<Color> heroGradient = [
    Color(0x002B2433),
    Color(0xCC2B2433),
  ];
}
