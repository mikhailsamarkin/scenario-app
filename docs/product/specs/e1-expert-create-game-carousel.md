---
spec_id: SP-E1-01
title: "Спецификация реализации: создание игры с каруселью и валидацией полей"
story_id: US-E1-01
status: approved
updated: "2026-09-07"
---
# Спецификация реализации — US-E1-01 «Создание игры с каруселью и валидацией полей»

## 1. Scope

**В объёме:**

* Канал «создать игру» для эксперта на раннем этапе: **импорт из репозитория** (`data/content/`) через скрипт в `tools/` (**ED-4**, **A-29a**) — поведение данных эквивалентно «создать игру».

* **Валидация полей игры** перед записью: обязательные поля, закрытые enum (**CR-4.1**), карусель (**CR-5**, **A-30**).

* **Публикация игры**: запись в Firestore (источник правды `games`) + сборка публичного агрегата `game_public/{gameId}` и обновление зависимых агрегатов (`home_feed`, `sitemap_public`) по денормализации **A-10**.

* **Загрузка изображений** слайдов в **Supabase Storage** (бакет `games`, пути `games/{id}/**`) — **ED-7**, **ED-14**, **A-39**.

* **Публичный read** опубликованной игры по правилам **A-38** (эмулятор-тесты; деплой правил — ADR-011).

* **Тесты**: unit-тесты валидатора (TC-02, TC-03), контрактные тесты (TC-04), эмулятор-тесты правил (TC-01/TC-04).

**Вне scope:**

* Отдельная веб-админка (**ED-4** — не инвестируем на этом этапе).

* Вёрстка сайта и экрана игры в МП (эпики **E2**, **E4**) — здесь только данные и публикация.

* Сценарии, связки `scenario_games`, `shortDescription` в контексте сценария — стори **US-E1-03**.

* Поля шаринга/SEO — стори **US-E1-04** (в `game_public` поля `seoTitle`/`seoDescription` присутствуют как опциональные, заполнение — отдельная стори).

* Деплой Firestore Rules в прод — **ADR-011** (здесь проектирование и эмулятор-тесты).

## 2. Требования → шаги

| #  | Требование                                          | Источник                 | Шаги |
| -- | --------------------------------------------------- | ------------------------ | ---- |
| R1 | Минимум один слайд `teaser` и валидные типы слайдов | AC-01, CR-5, A-30        | 3–4  |
| R2 | Enum-поля только из допустимых ключей               | AC-02, CR-4.1            | 3–4  |
| R3 | Обязательные поля игры заполнены                    | A-30, СТ §4.1            | 3–4  |
| R4 | Публикация: запись в Firestore + Storage            | AC-01, A-29, A-29a, ED-7 | 4–5  |
| R5 | Публичный read опубликованной игры                  | AC-03, A-29, A-38        | 6    |
| R6 | Черновики недоступны клиентскому read               | A-38                     | 6    |
| R7 | Импорт из репозитория эквивалентен «создать игру»   | ED-4, допущение TC       | 2, 4 |
| R8 | Контрактные тесты на схему и enum                   | TC-01..TC-04             | 6–7  |

## 3. Архитектура данных

```mermaid
flowchart TD
  subgraph SRC["Репозиторий (data/content)"]
    JSON[games/*.json]
    IMG[изображения слайдов]
  end

  IMP[Скрипт импорта tools/\nвалидация + upload + запись] -->|валидация CR-4.1, CR-5| JSON
| --- | --- | --- |
  IMP -->|upload ED-7, A-39| SB[(Supabase Storage\nbucket games)]
  IMP -->|запись service account| FS[(Firestore)]

  subgraph FS["Firestore"]
    G[games/{id} — источник правды, закрыт]
    GP[game_public/{gameId} — публичный агрегат]
    HF[home_feed/main — карусель]
    SM[sitemap_public/main — gameSlugs]
  end

  G -->|публикация A-10| GP
| --- | --- | --- |
  GP --> HF
  GP --> SM

  GP -->|read A-38| MP[МП / Flutter]
| --- | --- | --- |
  GP -->|read A-38| SITE[Next.js SSG]
  SB -->|public URL A-39| MP
  SB -->|public URL A-39| SITE
```

**Ключевые решения:**

* **Канал эксперта — импорт из репозитория** (**ED-4**): JSON-файлы игры в `data/content/games/`, изображения рядом; скрипт валидирует, загружает файлы в Supabase Storage, записывает `games/{id}` и собирает `game_public/{gameId}`. Отдельная админка не строится.

* **Валидация до записи** (**A-30**): единый валидатор (JSON Schema + проверки карусели) вызывается скриптом; невалидные данные не попадают в Firestore. Enum-allowlist — по **CR-4.1** (см. §4.2).

* **Источник правды закрыт** (**A-38**): `games` недоступен клиентскому read; клиенты читают только `game_public` (и `home_feed`/`sitemap_public`). Правила уже спроектированы в `scenario-site/firestore.rules` (SP-E0-01), деплой — ADR-011.

* **Медиа — Supabase Storage** (**ED-14**): `imageRef` слайда — путь `games/{id}/<file>`; публичный URL по правилу `supabasePublicUrl(path)` (**A-39**). Бакет `games` (public, 10MB, jpeg/png/webp) уже создан в dev/prod (SP-E0-02).

* **Денормализация при публикации** (**A-10**): `game_public` собирается из `games` + связей `scenario_games` (на момент стори — пустой список `scenarios`); `home_feed.carousel` и `sitemap_public.gameSlugs` обновляются при публикации игры.

## 4. Шаги (в порядке зависимостей)

### Шаг 1. Зафиксировать схему игры и слайда

Источник правды — **СТ §4.1** и **SP-E0-01 §4.1/§4.5**; артефакт — `docs/product/schemas/content-contract.schema.json` (уже содержит `gamePublic`, `slide`, enum-определения).

Документ `games/{id}` (источник правды, закрыт):

| Поле                         | Тип           | Обяз. | Комментарий                                            |
| ---------------------------- | ------------- | ----- | ------------------------------------------------------ |
| `id`                         | string        | да    | Стабильный ID игры                                     |
| `slug`                       | string        | да    | URL; уникальность проверяется до публикации (**ED-8**) |
| `title`                      | string        | да    | <br />                                                 |
| `seoTitle`, `seoDescription` | string        | нет   | Заполнение — US-E1-04                                  |
| `playersHint`                | enum          | да    | CR-4.1                                                 |
| `durationBucket`             | enum          | да    | CR-4.1                                                 |
| `ageHint`                    | enum          | да    | CR-4.1                                                 |
| `rulesComplexity`            | enum          | да    | CR-4.1                                                 |
| `carousel`                   | array\<Slide> | да    | CR-5; ≥1 слайд `teaser`                                |
| `createdAt`, `updatedAt`     | timestamp     | да    | Аудит                                                  |

`Slide` = `{ imageRef (string, да), frameType (enum, да), caption (string, нет), alt (string, нет) }`.

### Шаг 2. Подготовить фикстуры контента

* Каталог `data/content/games/` (сейчас в `data/content/` только `content-intake.xlsx` — исходные данные эксперта; формат JSON-фикстур фиксируется в этом шаге).

* Для каждой игры: JSON по схеме шага 1 + изображения слайдов (jpeg/png/webp, ≤10MB — лимит бакета).

* Минимум две фикстуры для тестов: валидная (с `teaser`) и невалидная (без `teaser`, с неизвестным enum) — по TC-01/TC-02/TC-03.

### Шаг 3. Валидатор игры

Реализация в `tools/` (Node + JSON Schema или эквивалент), вызывается скриптом импорта и unit-тестами:

* **Enum-allowlist** (**CR-4.1**, AC-02):

  * `playersHint`: `players_1`, `players_2`, `players_2_4`, `players_2_5`, `players_2_6`, `players_5_plus`

  * `durationBucket`: `warmup`, `short`, `evening`, `long`, `main_event`

  * `ageHint`: `age_kids`, `age_family`, `age_adults`

  * `rulesComplexity`: `easy`, `normal`, `heavy`

  * `frameType`: `teaser`, `box`, `in_play`, `mechanic_closeup`

* **Карусель** (**CR-5**, AC-01): непустой массив; каждый слайд — валидный `frameType`, обязательный `imageRef`; **минимум один слайд с** **`frameType == teaser`**.

* **Обязательные поля** (**A-30**): `id`, `slug`, `title`, четыре характеристики, `carousel`.

* **Тексты**: plain text, без Markdown/HTML (**A-4a**).

* Ошибки валидации — явные сообщения (например «carousel: требуется минимум один слайд frameType=teaser»), запись не выполняется.

### Шаг 4. Скрипт импорта/публикации игры

**Подготовка скрипта:**

* Место и окружение: `tools/`, Node.js ≥ 18, ESM-модули.

* Зависимости в `tools/package.json`: `firebase-admin` (запись в Firestore), `@supabase/supabase-js` (upload в Supabase Storage), `ajv` (валидация JSON по схеме контракта).

* Переменные окружения (вне git, A-40): `FIREBASE_SERVICE_ACCOUNT_PATH` (путь к service account key), `SUPABASE_URL` и `SUPABASE_SERVICE_ROLE_KEY` (по окружению dev/prod).

* Структура: `tools/validate-game.mjs` — валидатор (enum-allowlist CR-4.1, карусель CR-5, обязательные поля A-30); `tools/import-games.mjs` — оркестратор одной игры (валидация → upload → запись → сборка агрегатов); `tools/import-all.mjs` — оркестратор всех фикстур (валидация → импорт каждой).

* Команды: `node tools/import-games.mjs --project dev data/content/games/<id>.json` (и `--project prod`); флаг `--dry-run` — проверка без записи.

* Верификация: exit code 0 при успехе; явные ошибки валидации; лог без секретов; повторный запуск идемпотентен (update по id).

`tools/import-games.mjs` (Node + Firebase Admin SDK + Supabase Storage API), параметр `--project dev|prod` (по SP-E0-02 §7 follow-up):

1. Прочитать JSON игры из `data/content/games/`.
2. Прогнать валидатор (шаг 3); при ошибке — abort с кодом ≠ 0.
3. Проверить уникальность `slug` в `games` (**ED-8**).
4. Загрузить изображения слайдов в Supabase Storage: бакет `games`, путь `games/{id}/<filename>`; `imageRef` в данных заменяется на путь объекта (**ED-7**, **A-39**). Секреты service\_role — из env, вне репозитория (**A-40**).
5. Записать `games/{id}` (источник правды) через Admin SDK.
6. Собрать и записать `game_public/{gameId}`: поля по §4.5 SP-E0-01 (`id`, `slug`, `title`, `seoTitle?`, `seoDescription?`, четыре enum-характеристики, `carousel`, `scenarios` — на текущем этапе пустой массив, `contentVersion`, `updatedAt`).
7. Обновить зависимые агрегаты: добавить слайд(ы) игры в `home_feed.carousel` (по редакционному правилу — на текущем этапе все опубликованные игры с `teaser`), добавить `slug` в `sitemap_public.gameSlugs`; инкремент `contentVersion` (**A-10e, A-44**).
8. Идемпотентность: повторный запуск с теми же данными не создаёт дубликатов (update по `id`).

### Шаг 5. Storage Rules (Supabase)

| Уже выполнено в **SP-E0-02**: бакет `games` public, `file_size_limit 10MB`, \`allowed\_mime\_types image/jpeg | png | webp`; политика `public\_read\_games\` (SELECT для public); запись — только service\_role. Дополнительных изменений в этой стори не требуется; при необходимости — фиксация в ADR-011. |
| ------------------------------------------------------------------------------------------------------------- | --- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |

### Шаг 6. Firestore Rules и публичный read

Правила спроектированы в `scenario-site/firestore.rules` (SP-E0-01): `games` — `allow read, write: if false`; `game_public`, `home_feed`, `sitemap_public` — `allow read: if true; allow write: if false`; fail-closed для остальных путей. В этой стори:

* Эмулятор-тесты правил (расширение `scenario-site/scripts/tc-rules.mjs`): read `games/{id}` → denied; read `game_public/{id}` → ok (**AC-03**, TC-04).

* Деплой в прод — **ADR-011** (блокер публичного read в проде).

### Шаг 7. Тесты

| TC    | Слой             | Проверка                                            | Где                                |
| ----- | ---------------- | --------------------------------------------------- | ---------------------------------- |
| TC-01 | integration      | Сохранение игры с валидной каруселью (≥1 `teaser`)  | импорт на dev + эмулятор           |
| TC-02 | integration/unit | Карусель без `teaser` отклонена с явной ошибкой     | unit валидатора + e2e импорт       |
| TC-03 | unit             | Неизвестный enum отклонён; значение не записывается | параметризованные тесты валидатора |
| TC-04 | integration      | Публичный read `game_public` после публикации       | эмулятор правил + snapshot JSON    |

Существующие контрактные тесты `scenario/test/contract_test.dart` (строгий парсинг `GamePublic`, enum-ключи, round-trip) — база для TC-03/TC-04 на стороне Flutter.

**Локальный прогон импорта на dev-проекте:** `tools/import-all.mjs` валидирует все фикстуры из `data/content/games/` (кроме `invalid/`) без секретов, затем импортирует каждую на dev-проект `scenario-ba26a` через `import-games.mjs` (заметка TC-01). Один вызов: `node tools/import-all.mjs --project dev [--dry-run]` или `npm run import:dev` (в `tools/`). Секреты — из env (A-40); прогон идемпотентен и не требует ручных действий. Импорт из CI (GitHub Actions) не выполняется.

**Smoke и регресс:** smoke-набор — TC-01, TC-04; полный регресс — TC-01..TC-04 при изменении контракта карусели или enum (по тест-кейсам US-E1-01).

## 5. Файлы

* `docs/product/specs/e1-expert-create-game-carousel.md` — **настоящий документ** (SP-E1-01).

* `docs/product/schemas/content-contract.schema.json` — JSON Schema контракта (существует, SP-E0-01).

* `tools/import-games.mjs` (предлагается) — скрипт импорта/публикации игры.

* `tools/validate-game.mjs` (предлагается) — валидатор игры (enum, карусель, обязательные поля).

* `data/content/games/*.json` (предлагается) — фикстуры/контент игр.

* `scenario-site/firestore.rules` — правила публичного read (существуют, деплой ADR-011).

* `scenario-site/scripts/tc-rules.mjs` — эмулятор-тесты правил (расширение).

* `scenario/lib/data/contract/{enums,models,content_contract}.dart` — Dart-модели контракта (существуют).

* `scenario/test/contract_test.dart` — контрактные тесты (существуют).

* `tools/import-all.mjs` (предлагается) — локальный оркестратор импорта всех фикстур на dev (замена CI-прогона, TC-01).

## 6. Риски

* **Скрипт импорта отсутствует** (`tools/` содержит только README). Митиг: шаги 3–4 фиксируют минимальный объём; скрипт идемпотентен и валидирует до записи.

* **Деплой правил в прод отложен до ADR-011** — до деплоя Firestore закрыт целиком, публичный read в проде невозможен. Митиг: приёмка AC-03 в эмуляторе; деплой — отдельная задача.

* **Формат** **`content-intake.xlsx`** не зафиксирован — конвертация в JSON-фикстуры может потребовать уточнений у эксперта. Митиг: шаг 2 фиксирует схему фикстур; конвертация — отдельная подзадача.

* **Расхождение enum** между валидатором, правилами и UI. Митиг: единый источник — JSON Schema + Dart/TS типы (**СТ §4.1**), контрактные тесты.

* **Секреты** service\_role/Admin SDK — вне репозитория (**A-40**); скрипт не логирует ключи.

## 7. Follow-up (вне scope)

* Деплой Firestore Rules и Storage Rules — **ADR-011**.

* Связка игр со сценариями и `shortDescription` — **US-E1-03**.

* Поля шаринга/SEO — **US-E1-04**.

* Экран игры в МП (карусель, характеристики) — **US-E2-03**.

* Страница игры на сайте — эпик **E4**.

## 8. Доступы и блокеры

* Доступ к Firebase dev `scenario-ba26a` / prod `scenario-prod-491c` и Supabase service\_role (вне репозитория) для импорта.

* Согласование имён коллекций/агрегатов — **ADR-010**; деплой правил — **ADR-011**.

* **A-40:** секреты — только env/Secret Manager, не в git.

## 9. Verify

Соответствие критериям приёмки **US-E1-01**:

* **AC-01 (CR-5, A-30)** — TC-01/TC-02: валидатор пропускает карусель с ≥1 `teaser` и валидными типами; отклоняет карусель без `teaser` с явной ошибкой; запись не выполняется.

* **AC-02 (CR-4.1)** — TC-03: enum-значения вне allowlist отклоняются (параметризованные тесты по реестру из одного источника).

* **AC-03 (A-29)** — TC-04: после публикации `game_public/{gameId}` читается публичным клиентом по правилам; `games/{id}` недоступен.

Критерий готовности: импорт валидной игры на dev-проект проходит end-to-end (Storage + Firestore + агрегаты); TC-01..TC-04 зелёные; `game_public` соответствует JSON Schema.

## 10. История изменений

| Дата       | Автор | Изменение                                                                                                                            |
| ---------- | ----- | ------------------------------------------------------------------------------------------------------------------------------------ |
| 2026-09-06 | AID   | Первая версия (drafted). Канал импорта по ED-4, валидация CR-4.1/CR-5/A-30, публикация game\_public по A-10, публичный read по A-38. |

