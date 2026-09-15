---
story_id: US-E11-01
title: "Crashlytics в release: апгрейд google-services и подключение Gradle-плагина"
epic: "E11"
status: drafted
bt_refs: [FR-M-6]
st_refs: [A-41]
ed_refs: []
source_story: |
  Как команда, я хочу, чтобы Firebase Crashlytics собирал краши в release-сборке Android, чтобы видеть сбои реальных пользователей.
updated: "2026-09-11"
---

# Crashlytics в release: апгрейд google-services и подключение Gradle-плагина

## Ценность

Сейчас в release Crashlytics не работает: `FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true)` падает с `[firebase_crashlytics/unknown] FirebaseCrashlytics component is not present`, потому что нативный компонент не линкуется без Gradle-плагина. Краши продакшн-пользователей не доходят до консоли Firebase (**A-41**). Эта стори подключает плагин, чтобы отчёты собирались в release.

## Контекст и трассировка

| ID | Документ | Как используется в этой стори |
|----|----------|-------------------------------|
| FR-M-6 | БТ | Стабильность и аналитика |
| A-41 | СТ | Crashlytics: отчёты о сбоях |
| US-E6-05 | Стори | Исходная стори Crashlytics (реализована для debug) |

## Детали поведения

- Подключить Gradle-плагин `com.google.firebase.crashlytics` в `android/settings.gradle.kts` и `android/app/build.gradle.kts`.
- **Блокер версий:** плагин v3 требует `com.google.gms.google-services` ≥ 4.4.1 (сейчас 4.3.15); плагин v2 ломается на Gradle 9 (`groovy/util/XmlSlurper`).
- → Апгрейд `com.google.gms.google-services` до 4.4.1+ и подключение плагина v3.
- После апгрейда — пересобрать release и проверить, что:
  - старт проходит без `FirebaseCrashlytics component is not present`;
  - `startup:` маркеры доходят до `runApp scheduled`;
  - приложение не зависает (нет регресса предыдущего фикса INTERNET).

## Вне scope

- iOS Crashlytics.
- Удаление graceful-fallback в `main.dart` (можно оставить как защиту).

## Критерии приёмки (AC)

- **AC-01** *(СТ A-41)*
  - Given release-сборка Android
  - When происходит краш
  - Then отчёт попадает в Firebase Crashlytics.

- **AC-02**
  - Given release-сборка
  - When приложение стартует
  - Then старт не блокируется инициализацией Crashlytics (нет регресса зависания).

## Зависимости и блокеры

- Апгрейд `com.google.gms.google-services` до 4.4.1+.
- Совместимость с Gradle 9 / AGP 9.1.0.

## Открытые вопросы

- Нет.

## Примечания для downstream

- Проверить на эмуляторе: `./run_android_emulator.sh dev --build` и `adb logcat` на `startup:` маркеры.
- Убедиться, что в `aapt dump permissions` release-APK сохранён `android.permission.INTERNET`.