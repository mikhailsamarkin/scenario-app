---
spec_id: SP-E1-03
title: "Спецификация реализации: привязка игр к сценарию (порядок и shortDescription)"
story_id: US-E1-03
status: approved
updated: "2026-09-07"
---
# Спецификация реализации — US-E1-03 «Привязка игр к сценарию: порядок и shortDescription»

## 1. Scope

**В объёме:**

* **Связка сценарий–игра** `scenario_games` (источник правды, закрыт): для каждой игры в составе сценария задаётся `order` и контекстный `shortDescription` (**FR-B-1, CR-4**).

* **Импорт из репозитория** (`data/content/`) через скрипт в `tools/` (**ED-4**) — канал эксперта на раннем этапе; поведение данных эквивалентно «привязать игры к сценарию».

* **Валидация связки** перед записью: уникальность `order`, наличие `gameId`/`scenarioId`, plain text `shortDescription` (**A-4a**), отсутствие дублей пар.

* **Публикация денормализованных агрегатов** по **A-10**: `scenario_public/{scenarioId}.games` — упорядоченный список `ScenarioGameRef` (со `slug`, `shortDescription`, enum-чипами); `game_public/{gameId}.scenarios` — обратные ссылки `GameScenarioRef` (со `shortDescription` в контексте сценария).

* **Повторная публикация** при изменении только порядка/описания: обновление доступно клиенту без противоречия политике кэша (**AC-02**, версионирование по **A-10e/A-44**).

* **Тесты**: unit-тесты валидатора связки (TC-01, TC-02), контрактные тесты на `scenario_public.games` / `game_public.scenarios` (TC-02, TC-03).

**Вне scope:**

* UI МП (эпик **E2**) — здесь только данные и публикация; экран сценария/игры, кэш и синхронизация на стороне клиента (**FR-M-3**) — **US-E2-02/US-E2-03**.

* Группы смысла и «Сценарии прошлого» (эпик **E7**).

* Поля шаринга/SEO сценария — стори **US-E1-04** (в `scenario_public` поля присутствуют как опциональные, заполнение — отдельная стори).

* Деплой Firestore Rules в прод — **ADR-011** (здесь проектирование и эмулятор-тесты).

## 2. Требования → шаги

| #  | Требование                                          | Источник                 | Шаги |
| -- | --------------------------------------------------- | ------------------------ | ---- |
| R1 | Порядок игр в сценарии задан и сохраняется          | AC-01, FR-B-1, CR-4, A-10 | 3–4  |
| R2 | `shortDescription` в контексте пары сценарий–игра   | AC-01, CR-4, A-10, A-12   | 3–4  |
| R3 | Порядок попадает в публичный агрегат для чтения МП   | AC-01, A-10, A-10d        | 4    |
| R4 | Обновление только порядка/описания доступно клиенту  | AC-02, A-10e, A-44        | 4    |
| R5 | `shortDescription` — plain text (A-4a)               | AC-01, A-4a               | 3    |
| R6 | Импорт из репозитория эквивалентен «привязать игры»  | ED-4, допущение TC        | 2, 4 |
| R7 | Контрактные тесты на связку и агрегаты               | TC-01..TC-03              | 6–7  |

## 3. Архитектура данных

```mermaid
flowchart TD
  subgraph SRC["Репозиторий (data/content)"]
    SCJSON[scenarios/*.json\n+ games: [{gameId, order, shortDescription}]]
  end

  IMP[Скрипт импорта tools/\nвалидация + запись] -->|валидация CR-4, A-4a| SCJSON
  IMP -->|запись service account| FS[(Firestore)]

  subgraph FS["Firestore"]
    SG[scenario_games — источник правды, закрыт]
    SC[scenarios — источник правды, закрыт]
    G[games — источник правды, закрыт]
    SP[scenario_public/{scenarioId} — публичный агрегат]
    GPP[game_public/{gameId} — публичный агрегат]
  end

  SG -->|публикация A-10| SP
  SG -->|публикация A-10| GPP
  SC --> SP
  G --> GPP

  SP -->|read A-38| MP[МП / Flutter]
  GPP -->|read A-38| MP
```

**Ключевые решения:**

* **Канал эксперта — импорт из репозитория** (**ED-4**): JSON-файл сценария в `data/content/scenarios/` несёт массив `games` со связками `{gameId, order, shortDescription}`; скрипт валидирует, записывает `scenario_games` и пересобирает `scenario_public`/`game_public`. Отдельная админка не строится.

* **Источник правды — связка `scenario_games`** (**§4.3 SP-E0-01**): документ на пару `{scenarioId, gameId}` с полями `order`, `shortDescription`; пара уникальна. `order` — позиция игры в сценарии (1, 2, 3…), источник порядка в публичных данных.

* **Денормализация при публикации** (**A-10**): `scenario_public.games` собирается из `scenario_games` (сортировка по `order`) + данных игры из `games` (со `slug`, enum-чипами, `imageRef`); `game_public.scenarios` — обратные ссылки из `scenario_games` + `scenarios` (со `slug`, `shortDescription`). Оба списка несут `shortDescription` в контексте пары.

* **Контекстный `shortDescription`** (**A-12**): описание игры **в контексте сценария** хранится в связке, а не в игре; клиент для `game_detail` берёт запись из `game_public.scenarios` по нужному `scenarioId`.

* **Версионирование** (**A-10e, A-44**): при пересборке `scenario_public`/`game_public` инкрементируется `contentVersion` и обновляется `updatedAt` — основа инвалидации кэша на стороне клиента (**AC-02**, FR-M-3).

## 4. Шаги (в порядке зависимостей)

### Шаг 1. Зафиксировать схему связки сценарий–игра

Источник правды — **СТ §4.3** и **SP-E0-01 §4.3/§4.4/§4.5**; артефакт — `docs/product/schemas/content-contract.schema.json` (уже содержит `scenarioGameRef`, `gameScenarioRef`).

Документ `scenario_games/{scenarioId}_{gameId}` (источник правды, закрыт):

| Поле              | Тип     | Обяз. | Комментарий                                              |
| ----------------- | ------- | ----- | -------------------------------------------------------- |
| `scenarioId`      | string  | да    | == `scenarios.id`; часть ключа пары                      |
| `gameId`          | string  | да    | == `games.id`; часть ключа пары                          |
| `order`           | integer | да    | Позиция игры в сценарии; уникальна в пределах сценария   |
| `shortDescription`| string  | да    | Описание игры в контексте сценария; plain text (**A-4a**) |

Публичные представления (по **SP-E0-01 §4.4/§4.5**):

* `scenario_public/{scenarioId}.games` — `array<ScenarioGameRef>`, **упорядочен** по `order`; `ScenarioGameRef = { gameId, slug, title, shortDescription, imageRef, alt, playersHint, durationBucket, ageHint, rulesComplexity }`.

* `game_public/{gameId}.scenarios` — `array<GameScenarioRef>`; `GameScenarioRef = { scenarioId, slug, title, shortDescription }`.

### Шаг 2. Подготовить фикстуры контента

* Каталог `data/content/scenarios/` (по аналогии с `data/content/games/` из **US-E1-01**): JSON сценария по схеме шага 1 + массив `games` со связками.

* Для каждой связки: `gameId` существующей фикстуры игры, `order` (1..N без пропусков в рамках сценария), `shortDescription` (plain text).

* Минимум две фикстуры для тестов: валидная (связки с корректным порядком и текстами) и невалидная (дубль `order`, неизвестный `gameId`, `shortDescription` с Markdown/HTML) — по TC-01/TC-02/TC-03.

### Шаг 3. Валидатор связки сценарий–игра

Реализация в `tools/` (Node + JSON Schema или эквивалент), вызывается скриптом импорта и unit-тестами:

* **Порядок** (**CR-4**, AC-01): `order` — целое ≥ 1; значения уникальны в пределах сценария; при необходимости — непрерывны (1..N).

* **Ссылочная целостность**: `gameId` существует в `games` (источник правды); `scenarioId` существует в `scenarios`; пара `{scenarioId, gameId}` не дублируется.

* **`shortDescription`** (**A-4a**, AC-01): обязателен для каждой связки; plain text, без Markdown/HTML.

* **Enum-чипы** (для `ScenarioGameRef`): берутся из игры (`playersHint`, `durationBucket`, `ageHint`, `rulesComplexity`) — валидируются валидатором игры (**US-E1-01**, шаг 3), здесь только переносятся.

* Ошибки валидации — явные сообщения (например «scenario_games: order=2 дублируется для scenarioId=X»), запись не выполняется.

### Шаг 4. Скрипт импорта/публикации сценария со связками

**Подготовка скрипта:**

* Место и окружение: `tools/`, Node.js ≥ 18, ESM-модули; зависимости — `firebase-admin` (запись в Firestore), `ajv` (валидация JSON по схеме контракта). Переиспользует `tools/validate-game.mjs`/`tools/import-games.mjs` из **US-E1-01** (общие утилиты выносятся в общий модуль).

* Переменные окружения (вне git, **A-40**): `FIREBASE_SERVICE_ACCOUNT_PATH`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` (по окружению dev/prod).

* Структура: `tools/validate-scenario.mjs` — валидатор сценария и связок (порядок, ссылочная целостность, plain text); `tools/import-scenario.mjs` — оркестратор одного сценария (валидация → запись `scenarios`/`scenario_games` → сборка агрегатов); `tools/import-all.mjs` — расширяется на сценарии (валидация → импорт каждой фикстуры).

* Команды: `node tools/import-scenario.mjs --project dev data/content/scenarios/<id>.json` (и `--project prod`); флаг `--dry-run` — проверка без записи.

* Верификация: exit code 0 при успехе; явные ошибки валидации; лог без секретов; повторный запуск идемпотентен (update по паре).

`tools/import-scenario.mjs` (Node + Firebase Admin SDK), параметр `--project dev|prod`:

1. Прочитать JSON сценария из `data/content/scenarios/`.
2. Прогнать валидатор (шаг 3); при ошибке — abort с кодом ≠ 0.
3. Проверить уникальность `slug` сценария в `scenarios` (**ED-8**).
4. Записать/обновить `scenarios/{id}` (источник правды) через Admin SDK.
5. Записать связки `scenario_games/{scenarioId}_{gameId}`: `{scenarioId, gameId, order, shortDescription}`; удалить связки, которых больше нет в данных (синхронизация состава).
6. Собрать и записать `scenario_public/{scenarioId}`: поля по §4.4 SP-E0-01; `games` — массив `ScenarioGameRef`, отсортированный по `order`, `shortDescription` из связки, остальные поля из `games`; инкремент `contentVersion`, `updatedAt`.
7. Обновить обратные ссылки `game_public/{gameId}.scenarios` для каждой затронутой игры: добавить/обновить/удалить `GameScenarioRef` (со `slug`, `title`, `shortDescription`); инкремент `contentVersion`, `updatedAt` (**A-10e, A-44**).
8. Идемпотентность: повторный запуск с теми же данными не создаёт дубликатов (update по паре `{scenarioId, gameId}`).

### Шаг 5. Firestore Rules и публичный read

Правила спроектированы в `scenario-site/firestore.rules` (SP-E0-01): `scenario_games`, `scenarios`, `games` — `allow read, write: if false`; `scenario_public`, `game_public` — `allow read: if true; allow write: if false`; fail-closed для остальных путей. В этой стори:

* Эмулятор-тесты правил (расширение `scenario-site/scripts/tc-rules.mjs`): read `scenario_games/{id}` → denied; read `scenario_public/{id}` → ok (**AC-01**, TC-01/TC-02).

* Деплой в прод — **ADR-011** (блокер публичного read в проде).

### Шаг 6. Тесты

| TC    | Слой             | Проверка                                                                  | Где                              |
| ----- | ---------------- | ------------------------------------------------------------------------- | -------------------------------- |
| TC-01 | integration      | Порядок игр в `scenario_public.games` совпадает с заданным `order`        | импорт на dev + эмулятор         |
| TC-02 | integration     | `shortDescription` для пары сценарий–игра в публичном read                 | эмулятор правил + snapshot JSON  |
| TC-03 | integration     | Изменение только порядка/состава доступно клиенту; версия инкрементируется | повторный импорт + diff          |

Существующие контрактные тесты `scenario/test/contract_test.dart` (строгий парсинг `ScenarioPublic`/`GamePublic`, enum-ключи, round-trip) — база для TC-01/TC-02 на стороне Flutter.

**Локальный прогон импорта на dev-проекте:** `tools/import-all.mjs` валидирует все фикстуры из `data/content/scenarios/` (кроме `invalid/`) без секретов, затем импортирует каждую на dev-проект `scenario-ba26a` через `import-scenario.mjs`. Один вызов: `node tools/import-all.mjs --project dev [--dry-run]` или `npm run import:dev` (в `tools/`). Секреты — из env (A-40); прогон идемпотентен и не требует ручных действий. Импорт из CI (GitHub Actions) не выполняется.

**Smoke и регресс:** smoke-набор — TC-01, TC-02; полный регресс — TC-01..TC-03 при изменении схемы связки E0 (по тест-кейсам US-E1-03).

## 5. Файлы

* `docs/product/specs/e1-expert-scenario-games-order-short-description.md` — **настоящий документ** (SP-E1-03).

* `docs/product/schemas/content-contract.schema.json` — JSON Schema контракта (существует, SP-E0-01; содержит `scenarioGameRef`, `gameScenarioRef`).

* `tools/import-scenario.mjs` (предлагается) — скрипт импорта/публикации сценария со связками.

* `tools/validate-scenario.mjs` (предлагается) — валидатор сценария и связок (порядок, ссылочная целостность, plain text).

* `tools/import-all.mjs` (расширение) — локальный оркестратор импорта всех фикстур (игры + сценарии) на dev.

* `data/content/scenarios/*.json` (предлагается) — фикстуры/контент сценариев со связками игр.

* `scenario-site/firestore.rules` — правила публичного read (существуют, деплой ADR-011).

* `scenario-site/scripts/tc-rules.mjs` — эмулятор-тесты правил (расширение).

* `scenario/lib/data/contract/{enums,models,content_contract}.dart` — Dart-модели контракта (существуют; `ScenarioPublic`, `GamePublic`).

* `scenario/test/contract_test.dart` — контрактные тесты (существуют).

## 6. Риски

* **Скрипт импорта сценариев отсутствует** (`tools/` содержит только README; есть только игра-пайплайн US-E1-01). Митиг: шаги 3–4 переиспользуют общие утилиты US-E1-01; скрипт идемпотентен и валидирует до записи.

* **Деплой правил в прод отложен до ADR-011** — до деплоя Firestore закрыт целиком, публичный read в проде невозможен. Митиг: приёмка AC-01 в эмуляторе; деплой — отдельная задача.

* **Расхождение порядка/состава** между источником и агрегатами при повторной публикации. Митиг: шаг 4 синхронизирует состав (удаляет отсутствующие связки) и сортирует по `order`; TC-03 проверяет diff.

* **Расхождение enum** между валидатором, правилами и UI. Митиг: единый источник — JSON Schema + Dart/TS типы (**СТ §4.1**), контрактные тесты.

* **Секреты** service\_role/Admin SDK — вне репозитория (**A-40**); скрипт не логирует ключи.

## 7. Follow-up (вне scope)

* Деплой Firestore Rules и Storage Rules — **ADR-011**.

* Экран сценария в МП (порядок игр, `shortDescription`, кэш/синхронизация FR-M-3) — **US-E2-02/US-E2-03**.

* Поля шаринга/SEO сценария — **US-E1-04**.

* Группы смысла и «Сценарии прошлого» — эпик **E7**.

* Страница сценария на сайте — эпик **E4**.

## 8. Доступы и блокеры

* Доступ к Firebase dev `scenario-ba26a` / prod `scenario-prod-491c` и Supabase service\_role (вне репозитория) для импорта.

* Согласование имён коллекций/агрегатов — **ADR-010**; деплой правил — **ADR-011**.

* **A-40:** секреты — только env/Secret Manager, не в git.

## 9. Verify

Соответствие критериям приёмки **US-E1-03**:

* **AC-01 (FR-B-1, CR-4, A-10)** — TC-01/TC-02: после публикации `scenario_public/{scenarioId}.games` отражает заданный порядок и `shortDescription` каждой пары; `game_public/{gameId}.scenarios` несёт обратные ссылки со `shortDescription` в контексте.

* **AC-02 (A-10e, A-44)** — TC-03: изменение только порядка/описания при повторной публикации доступно клиенту; `contentVersion`/`updatedAt` обновлены для инвалидации кэша без противоречия FR-M-3 на стороне клиента (см. E2).

Критерий готовности: импорт валидного сценария со связками на dev-проект проходит end-to-end (Firestore + агрегаты); TC-01..TC-03 зелёные; `scenario_public`/`game_public` соответствуют JSON Schema.

## 10. История изменений

| Дата       | Автор | Изменение                                                                                                                            |
| ---------- | ----- | ------------------------------------------------------------------------------------------------------------------------------------ |
| 2026-09-07 | AID   | Первая версия (drafted). Связка scenario\_games по CR-4, порядок и shortDescription в публичных агрегатах по A-10, версионирование по A-10e/A-44. |