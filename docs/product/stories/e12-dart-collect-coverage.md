---
story_id: US-E12-04
title: "Применение dart-collect-coverage (dart-lang/skills): покрытие тестов и LCOV в CI"
epic: "E12"
status: drafted
bt_refs: []
st_refs: []
ed_refs: []
source_story: |
  Как команда, я хочу применять skill dart-collect-coverage и собирать покрытие тестов (LCOV) в CI, чтобы видеть реальное покрытие сервисов и не допускать регрессий.
updated: "2026-09-16"
---

# Применение dart-collect-coverage (dart-lang/skills): покрытие тестов и LCOV в CI

## Ценность

Сейчас CI ([.github/workflows/ci.yml](../../../.github/workflows/ci.yml)) прогоняет `gitleaks`, `flutter analyze` и сборку APK, но **не запускает `flutter test`** и не собирает покрытие — 20 тестовых файлов в `test/` не участвуют в гейте качества. Официальный skill **`dart-collect-coverage`** (repo `dart-lang/skills`) задаёт процесс: добавить `coverage` в `dev_dependencies`, сгенерировать LCOV одной командой `dart run coverage:test_with_coverage`, исключать непокрываемое директивами `// coverage:ignore-*`, при необходимости — ручной сбор через VM service.

Эта стори внедряет сбор покрытия и прогон тестов в CI, не меняя prod-код приложения.

## Контекст и трассировка

| ID | Документ / ссылка | Как используется в этой стори |
|----|-------------------|-------------------------------|
| Skill | `dart-collect-coverage` (github.com/dart-lang/skills) | Источник процесса сбора покрытия и формата LCOV |
| `test/` | 20 тестовых файлов | Существующие тесты, которые лягут под покрытие |
| `.github/workflows/ci.yml` | CI | Добавляется шаг `flutter test` + публикация `lcov.info` |
| US-E12-01 / US-E12-03 | Стори | Сервисный и репозиторный слои — основные цели покрытия после рефакторинга |

Прямой трассировки на БТ/СТ у истории нет: это внутренняя работа по качеству.

## Детали поведения

- Запустить skill и следовать его инструкциям:
  ```bash
  npx skills use "https://github.com/dart-lang/skills" --skill "dart-collect-coverage"
  ```
- **Прочитать полный вывод скилла** (при необходимости сначала перенаправить его в временный файл).
- **Относительные пути резолвить от каталога supporting-files**, который вернёт скилл (а не от корня проекта).
- Добавить `coverage` строго в `dev_dependencies` (не в `dependencies`).
- Сгенерировать покрытие и убедиться, что создаются `coverage/coverage.json` и `coverage/lcov.info`:
  ```bash
  dart run coverage:test_with_coverage
  ```
  Если для Flutter-проекта команда требует уточнения — использовать ручной workflow из скилла (VM service + `collect_coverage`/`format_coverage`).
- Исключить сгенерированное и непокрываемое (`// coverage:ignore-file`, `// coverage:ignore-line`, `// coverage:ignore-start/end`).
- Добавить в CI шаг прогона тестов и публикации `coverage/lcov.info` как артефакта; `flutter analyze`/сборка остаются как есть.
- Пороговое значение покрытия в первой итерации **не** блокирует сборку (фиксируется отдельно).
- **Поведение приложения не меняется:** продовый код не затрагивается.

## Вне scope

- Написание новых тестов ради роста процента (см. skill `dart-add-unit-test` — отдельная работа).
- Политика и пороги покрытия как обязательный гейт (обсуждается отдельно).
- Покрытие сайта `scenario-site/` (JS) — вне эпика МП.

## Критерии приёмки (AC)

- **AC-01**
  - Given репозиторий `scenario`
  - When выполнен запуск `npx skills use "https://github.com/dart-lang/skills" --skill "dart-collect-coverage"` и прочитан его полный вывод
  - Then инструкции применены, `coverage` добавлен в `dev_dependencies`, относительные пути резолвятся от supporting-files.

- **AC-02**
  - Given существующий набор тестов
  - When выполнена команда сбора покрытия
  - Then локально сформирован `coverage/lcov.info`, директивы `coverage:ignore-*` учитываются.

- **AC-03**
  - Given обновлённый CI
  - When выполняются push в `main` / pull request
  - Then тесты запускаются, `lcov.info` публикуется артефактом, а `flutter analyze` и сборка APK остаются зелёными.

## Зависимости и блокеры

- Доступ в сеть для `npx skills use`; Dart/Flutter SDK.
- Правки `.github/workflows/ci.yml` (добавление шага тестов и артефакта).
- Возможные отличия `dart run coverage:test_with_coverage` для Flutter — проверить и при необходимости использовать ручной сбор из скилла.

## Открытые вопросы

- Задавать ли порог покрытия, на каком уровне и по каким слоям (сервисы/репозитории)?
- Публиковать покрытие в PR-комментарий / внешний сервис (Codecov и т.п.) или достаточно артефакта?
- Только МП или включать покрытие других Dart-пакетов репозитория?

## Примечания для downstream

- После внедрения обновить README/описание CI.
- Связать рост покрытия с US-E12-01/03 (после выделения сервисов и репозиториев).
