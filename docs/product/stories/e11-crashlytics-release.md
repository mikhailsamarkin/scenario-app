---
epic_id: E11
title: "Стабильность Android-сборки: Crashlytics в release"
status: drafted
bt_refs: [FR-M-6]
st_refs: [A-41]
ed_refs: []
source_story: |
  Как команда, я хочу, чтобы Firebase Crashlytics работал в release-сборке Android, чтобы видеть краши реальных пользователей и чинить стабильность.
updated: "2026-09-11"
---

# Стабильность Android-сборки: Crashlytics в release

## Ценность

Сейчас Crashlytics работает только в debug-сборке. В release нативный компонент не линкуется (`FirebaseCrashlytics component is not present`), поэтому краши продакшн-пользователей не попадают в консоль Firebase. Эта стори подключает Crashlytics Gradle-плагин, чтобы отчёты о сбоях собирались и в release (**A-41**).

## Контекст и трассировка

| ID | Документ | Как используется в эпике |
|----|----------|---------------------------|
| FR-M-6 | БТ | Стабильность и аналитика |
| A-41 | СТ | Crashlytics: отчёты о сбоях |
| US-E6-05 | Стори | Исходная стори Crashlytics (реализована для debug) |

## Контекст проблемы

- `lib/main.dart` вызывает `FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true)`.
- В debug-сборке работает; в release падает с `[firebase_crashlytics/unknown] FirebaseCrashlytics component is not present`.
- Причина: для release нужен Gradle-плагин `com.google.firebase.crashlytics`, который не подключён.
- Сейчас инициализация обёрнута в `try/catch` (graceful-fallback) — приложение стартует, но Crashlytics в release не собирает краши.

## Зависимости и блокеры

- Плагин `com.google.firebase.crashlytics` **v3** требует `com.google.gms.google-services` ≥ **4.4.1** (у проекта сейчас 4.3.15).
- Плагин **v2** ломается на Gradle 9 (`groovy/util/XmlSlurper`).
- → Требуется апгрейд `com.google.gms.google-services` до 4.4.1+ и подключение плагина v3.

## Стори эпика

| ID | Сторя | Файл |
|----|-------|------|
| US-E11-01 | Crashlytics в release: апгрейд google-services и подключение Gradle-плагина | [e11-crashlytics-release-gradle.md](e11-crashlytics-release-gradle.md) |

## Критерии приёмки (AC)

- **AC-01** *(СТ A-41)*
  - Given release-сборка Android
  - When происходит краш
  - Then отчёт попадает в Firebase Crashlytics.

- **AC-02**
  - Given release-сборка
  - When приложение стартует
  - Then старт не блокируется инициализацией Crashlytics (нет регресса зависания).

## Вне scope

- iOS Crashlytics (отдельная проверка).
- Другие стабильностные задачи.

## Открытые вопросы

- Нет.

## Примечания для downstream

- После апгрейда google-services — пересобрать и проверить release на эмуляторе (`run_android_emulator.sh dev --build`).
- Убедиться, что `startup:` маркеры проходят до `runApp scheduled`.