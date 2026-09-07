// Локальные настройки приложения (shared_preferences).
//
// Хранит флаг «онбординг пройден» (A-17, SP-E3-01), чтобы показывать
// онбординг только при первом запуске.

import 'package:shared_preferences/shared_preferences.dart';

/// Ключ флага «онбординг пройден».
const String kOnboardingCompletedKey = 'onboarding_completed';

/// Источник флага «онбординг пройден» (абстракция для тестируемости).
abstract interface class OnboardingStatusSource {
  Future<bool> isCompleted();
}

/// Реализация поверх shared_preferences.
class SharedPrefsOnboardingStatus implements OnboardingStatusSource {
  @override
  Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kOnboardingCompletedKey) ?? false;
  }
}

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