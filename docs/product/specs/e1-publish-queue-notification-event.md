---
spec_id: SP-E1-05
title: "Спецификация реализации: очередь уведомлений при первой публикации сценария"
story_id: US-E1-05
status: drafted
updated: "2026-09-07"
---
# Спецификация реализации — US-E1-05 «Очередь уведомлений при первой публикации сценария»

## 1. Scope

**В объёме:**

* **Событие в очереди при первой публикации сценария** (**A-31**, **FR-B-4**): при переходе сценария в состояние `published: true` из «не опубликован» (первичная публикация или переход из черновика) обновляется **единая запись очереди** `pending_notifications/daily` полем `lastScenarioId` и меткой времени. При нескольких публикациях за сутки запись **перезаписывается последней** (**A-7a**).

* **Отсутствие события при правке только состава игр** (**A-33**, **FR-M-4**): изменение порядка/состава игр у уже опубликованного сценария **не** создаёт новое событие «новинка дня» в очереди.

* **Backend-only без FCM** (срез без push, **use-cases** US-E1-05): очередь и триггер реализуются без FCM и scheduler; данные готовы к подключению **E3** без миграции формата (**AC-03**).

* **Формат записи очереди** (**ED-11**): JSON Schema payload в контракте (`pending_notifications/daily`), валидируемая до записи и достаточная для scheduler и deep link при включении E3.

* **Тесты**: TC-01…TC-03 из `docs/product/test-cases/e1-publish-queue-notification-event.md` (запись в очереди после первой публикации; отсутствие события при смене только игр; валидность формата для E3).

**Вне scope:**

* FCM, topic `new_scenarios` и отправка push — **US-E3-02/US-E3-03** (**SR-PUSH-1**, **A-32**).

* Scheduler / Cloud Functions `dailyPush` (отправка в 11:00 МСК) — **US-E3-03** (в `scenario-site/functions` уже есть заготовка `dailyPush`; здесь не меняется).

* Deep link из push на экран сценария — **US-E3-04**.

* Тексты и тон push — организационно (**use-cases** §6.4); технически — **ED-11** (поля в Firestore/конфиге, подключаются при E3).

## 2. Требования → шаги

| #  | Требование                                                       | Источник                    | Шаги        |
| -- | ---------------------------------------------------------------- | --------------------------- | ----------- |
| R1 | Первая публикация сценария создаёт/обновляет запись очереди       | AC-01, A-31, FR-B-4         | 1, 2, 3     |
| R2 | Несколько публикаций за сутки — перезапись последней              | A-7a, A-31                  | 2, 3        |
| R3 | Правка только состава игр у опубликованного не создаёт событие    | AC-02, A-33, FR-M-4         | 2, 3, 4     |
| R4 | Формат записи валиден и готов к E3 без миграции                   | AC-03, ED-11                | 1, 3, 5     |
| R5 | Backend-only: без FCM/scheduler до включения E3                   | use-cases US-E1-05, AC-03   | 3, 6        |
| R6 | Тесты на триггер и формат                                         | TC-01…TC-03                 | 4, 5, 6     |

## 3. Архитектура данных

```mermaid
flowchart TD
  subgraph SRC["Репозиторий (data/content)"]
    SCJSON[scenarios/*.json
+ published: true/false]
  end

  IMP[Скрипт импорта tools/import-scenario.mjs
+ определение «первой публикации»] -->|валидация + запись| SCJSON

  subgraph FS["Firestore"]
    SC[scenarios/{id} - источник правды, закрыт]
    SP[scenario_public/{scenarioId} - публичный агрегат]
    Q[(pending_notifications/daily
+ lastScenarioId, updatedAt)]
  end

  IMP -->|первая публикация A-31| SC
  IMP -->|первая публикация A-31| Q
  SC -->|публикация A-10| SP

  Q -->|11:00 МСК, A-32| PUSH[E3: dailyPush -> FCM topic new_scenarios]
```

**Ключевые решения:**

* **Триггер публикации — скрипт импорта** (**ED-4**): публикация сценария в текущей архитектуре выполняется `tools/import-scenario.mjs` (запись Admin SDK). Логика очереди добавляется в этот скрипт — это и есть «триггер публикации» на текущем этапе. Отдельная Cloud Function на запись `scenarios` не вводится (дублирование с импортом; деплой функций — отдельная задача).

* **Единая запись очереди** (**A-31, A-7a**): `pending_notifications/daily` — один документ, который перезаписывается при каждой новой публикации за сутки (`lastScenarioId` = последний опубликованный). Это соответствует «одному push в сутки на последний сценарий» (**A-32**, **US-E3-03**).

* **Определение «первой публикации»** (открытый вопрос стори): событие создаётся, когда сценарий **переходит** в `published: true` из состояния «не опубликован» — документ `scenarios/{id}` отсутствует (первичная публикация) или `published` был `false` (переход из черновика). Если сценарий уже был `published: true` (републикация/правка, в т.ч. только состава игр) — событие **не** создаётся (**A-33**). Это не противоречит A-33 и закрывает открытый вопрос стори.

* **Формат записи** (**ED-11**): `{ lastScenarioId: string, updatedAt: ISO-8601 }`. Поля достаточны для scheduler (deep link по `lastScenarioId`) и не требуют миграции при подключении E3 (**AC-03**). Тексты push — отдельно при E3 (**ED-11**).

* **Backend-only** (**AC-03**): FCM и scheduler не подключаются; приёмка — «очередь и триггеры реализованы/зафлажены».

## 4. Шаги (в порядке зависимостей)

### Шаг 1. Зафиксировать схему записи очереди в контракте

Артефакт: `docs/product/schemas/content-contract.schema.json` (SP-E0-01). Добавить определение `pendingNotificationDaily` и ссылку на него в `oneOf`:

```json
"pendingNotificationDaily": {
  "type": "object",
  "additionalProperties": false,
  "required": ["lastScenarioId", "updatedAt"],
  "properties": {
    "lastScenarioId": { "type": "string" },
    "updatedAt": { "$ref": "#/definitions/updatedAt" }
  }
}
```

`updatedAt` уже определён в контракте (ISO-8601). Это источник правды формата очереди для **ED-11** и основа TC-03.

### Шаг 2. Определить «первую публикацию» в коде

Новый модуль `tools/notification-queue.mjs` (Node, ESM) с чистыми функциями:

* `isFirstPublication(previous, next)` — возвращает `true`, если `next.published === true` и (`previous` отсутствует **или** `previous.published !== true`); иначе `false`. Это формализация A-31/A-33 (см. §3 «Ключевые решения»).
* `buildDailyQueueRecord(scenarioId, updatedAt)` — собирает `{ lastScenarioId, updatedAt }` по A-31.
* `validateQueueRecord(record)` — проверяет запись по схеме Шага 1 (обязательные поля, типы); возвращает `{ ok, errors }`.

### Шаг 3. Интегрировать очередь в `tools/import-scenario.mjs`

В `publishScenario`:

1. Перед записью `scenarios/{id}` прочитать существующий документ `scenarios/{id}` (если есть) — `previous`.
2. Вычислить `firstPublication = isFirstPublication(previous, scenario)`.
3. После успешной публикации (после обновления зависимых агрегатов `home_feed`/`sitemap_public`), если `firstPublication` — записать `pending_notifications/daily` через `buildDailyQueueRecord` (перезапись последней, **A-7a**). В `--dry-run` — только лог.
4. Если `firstPublication === false` (в т.ч. правка только состава игр у опубликованного) — очередь **не** трогается (**A-33**).

Идемпотентность: повторный запуск с теми же данными у уже опубликованного сценария не создаёт событие (первая публикация уже была).

### Шаг 4. Unit-тесты триггера

`tools/test/notification-queue.test.mjs` (node --test), покрывает:

* `isFirstPublication`: первичная публикация (`previous = null`) → `true`; переход из черновика (`previous.published === false`) → `true`; републикация уже опубликованного → `false`; сценарий не публикуется (`next.published === false`) → `false` (TC-01/TC-02).
* `buildDailyQueueRecord`: поля `lastScenarioId`/`updatedAt` заполнены (TC-01).
* `validateQueueRecord`: валидная запись проходит; отсутствие `lastScenarioId`/`updatedAt` → ошибка (TC-03).

### Шаг 5. Валидация формата (TC-03)

Прогон записи очереди через `validateQueueRecord` (и JSON Schema из Шага 1) — поля достаточны для scheduler и deep link без миграции при E3. Валидация вызывается перед записью в Шаге 3.

### Шаг 6. Тесты

Соответствие тест-кейсам `docs/product/test-cases/e1-publish-queue-notification-event.md` (TC-01…TC-03):

| TC  | Слой | Проверка | Где |
| --- | ---- | -------- | --- |
| TC-01 | integration | Первая публикация создаёт запись `pending_notifications/daily` с `lastScenarioId` | unit `isFirstPublication`/`buildDailyQueueRecord` + импорт на dev |
| TC-02 | integration | Смена только состава/порядка игр у опубликованного не создаёт событие | unit `isFirstPublication` (републикация → false) + импорт на dev |
| TC-03 | contract | Запись валидируется схемой, поля достаточны для E3 | `validateQueueRecord` + JSON Schema |

* Локальный прогон: `cd scenario/tools && node --test test/notification-queue.test.mjs`.
* Импорт E2E на dev (если доступны ключи) — по скиллу **scenario-e2e** (`tools/import-all.mjs --project dev`), затем чтение `pending_notifications/daily`.

## 5. Файлы

* `docs/product/specs/e1-publish-queue-notification-event.md` — **настоящий документ** (SP-E1-05).
* `docs/product/schemas/content-contract.schema.json` — JSON Schema: добавление `pendingNotificationDaily` (ED-11).
* `tools/notification-queue.mjs` (предлагается) — `isFirstPublication`, `buildDailyQueueRecord`, `validateQueueRecord`.
* `tools/import-scenario.mjs` — интеграция очереди (определение первой публикации + запись `pending_notifications/daily`).
* `tools/test/notification-queue.test.mjs` (предлагается) — unit-тесты триггера и формата.
* `docs/product/test-cases/e1-publish-queue-notification-event.md` — тест-кейсы TC-01…TC-03 (существуют).
* `scenario-site/functions/src/index.ts` — `dailyPush` (существует, **не меняется** в этой стори; используется при E3).

## 6. Риски

* **Дублирование триггера** (импорт vs Cloud Function): если позже введут Cloud Function на запись `scenarios`, событие может создаваться дважды. Митиг: на текущем этапе триггер только в импорте; при переходе на функции — перенести логику и убрать из импорта (follow-up).
* **Определение «первой публикации»**: риск расхождения с ожиданиями PO. Митиг: формализация в `isFirstPublication` (A-31/A-33), синхронизация с PO при расхождении (открытый вопрос стори).
* **Формат очереди при E3**: риск миграции при подключении push. Митиг: схема зафиксирована в контракте (Шаг 1), TC-03 проверяет достаточность полей.
* **Секреты** (Admin SDK) — только env, не в git (**A-40**).

## 7. Follow-up (вне scope)

* Подписка на topic и отправка push — **US-E3-02/US-E3-03** (**A-32**, **SR-PUSH-1**).
* Deep link из push — **US-E3-04**.
* Тексты push в Firestore/конфиге — **ED-11** (при E3).
* Перенос триггера в Cloud Function при переходе на функции (если потребуется).

## 8. Доступы и блокеры

* Доступ к Firebase dev `scenario-ba26a` / prod `scenario-prod-491c` для импорта (вне git, **A-40**).
* FCM и Scheduler — блокер полного E3, **не** блокер этой стори (срез без push, **AC-03**).
* Деплой Cloud Functions — отдельная задача (при E3).

## 9. Verify

Соответствие критериям **US-E1-05**:

* **AC-01 (A-31, FR-B-4)** — TC-01: после первой публикации в `pending_notifications/daily` появляется запись с `lastScenarioId` и `updatedAt`.
* **AC-02 (A-33, FR-M-4)** — TC-02: у уже опубликованного сценария смена только состава/порядка игр не создаёт новое событие.
* **AC-03 (срез без push)** — TC-03: запись валидируется схемой и достаточна для подключения E3 без миграции формата.

Критерий готовности: unit-тесты `notification-queue.test.mjs` зелёные; `import-scenario.mjs` при первой публикации пишет `pending_notifications/daily`, при правке только игр — не пишет; запись соответствует JSON Schema.

## 10. История изменений

| Дата  | Автор | Изменение |
| ----- | ----- | --------- |
| 2026-09-07 | AID | Первая версия (drafted): формат очереди `pending_notifications/daily` (A-31), определение «первой публикации» (A-31/A-33), интеграция в `import-scenario.mjs`, схема в контракте (ED-11), тесты TC-01…TC-03. |
