// Локальные настройки приложения (shared_preferences).
//
// Хранит флаг «онбординг пройден» (A-17, SP-E3-01), чтобы показывать
// онбординг только при первом запуске.

import 'package:shared_preferences/shared_preferences.dart';

/// Ключ флага «онбординг пройден».
const String kOnboardingCompletedKey = 'onboarding_completed';

/// Читает флаг «онбординг пройден». По умолчанию false (первый запуск).
Future<bool> isOnboardingCompleted() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(kOnboardingCompletedKey) ?? false;
}

/// Помечает онбординг как пройденный.
Future<void> markOnboardingCompleted() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(kOnboardingCompletedKey, true);
}