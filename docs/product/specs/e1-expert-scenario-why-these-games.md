---
spec_id: SP-E1-02
title: "Спецификация реализации: сценарий с текстом «почему эти игры подходят» и витриной"
story_id: US-E1-02
status: approved
updated: "2026-09-07"
---
# Спецификация реализации — US-E1-02 «Сценарий с "почему эти игры подходят" и витриной»

## 1. Scope

**В объёме:**

* **Поле `whyTheseGames`** (единый текст-обоснование подбора, **CR-4**): обязательность для публикации, формат **plain text** с сохранением переносов `\n`, **без** Markdown/HTML (**A-4a**, **СТ §4.2**) — и его попадание в публичный агрегат `scenario_public/{scenarioId}.whyTheseGames`.

* **Признаки витрины сценария** `onHomeVitrine` / `vitrineOrder` (**FR-B-1**, **CR-4**, **СТ §4.2**): валидация при импорте и хранение в источнике правды `scenarios/{id}`.

* **Сборка/обновление публичной витрины** `home_feed/main.vitrine` (array\<ScenarioCard\>) при публикации сценария — **только опубликованные** сценарии с `onHomeVitrine: true`, отсортированные по `vitrineOrder` (**FR-B-1**, **СТ §4.2 / SP-E0-01 §4.2**). Главный экран МП получает список из агрегата без релиза приложения (**AC-02**).

* **Поддержка `sitemap_public/main.scenarioSlugs`** (все опубликованные `slug` сценариев) — производный индекс для SSG без N+1 (**A-10b, A-10d**).

* **Импорт из репозитория** `data/content/scenarios/*.json` через скрипт `tools/import-scenario.mjs` — канал эксперта на раннем этапе (**ED-4**); поведение данных эквивалентно «создать сценарий с обоснованием и витриной».

* **Тесты**: unit-тесты валидатора (TC-01, TC-02), контрактные тесты `home_feed.vitrine` / `sitemap_public.scenarioSlugs` (TC-03, TC-04).

**Вне scope:**

* UI главного экрана/витрины МП (эпик **E2**, **US-E2-01**) — здесь только **данные и публикация**; чтение `home_feed` и рендер витрины — E2.

* Группы смысла и «Сценарии прошлого» (эпик **E7**).

* Поля шаринга/SEO сценария — стори **US-E1-04** (в `scenario_public` поля присутствуют как опциональные, заполнение — отдельная стори).

* Деплой Firestore Rules в прод — **ADR-011** (здесь проектирование и эмулятор-тесты).

## 2. Требования → шаги

| # | Требование | Источник | Шаги |
| -- | --- | --- | --- |
| R1 | `whyTheseGames` обязателен при публикации | AC-01, FR-B-1, CR-4, A-30 | 2 |
| R2 | `whyTheseGames` — plain text с сохранением `\n`, без Markdown/HTML | AC-01, A-4a, СТ §4.2 | 2, 4 |
| R3 | `whyTheseGames` попадает в `scenario_public` для чтения | AC-01, A-10, СП-E1-03 | 4 |
| R4 | `onHomeVitrine`/`vitrineOrder` валидируются и хранятся в источнике правды | AC-02, FR-B-1, CR-4 | 2, 3 |
| R5 | `home_feed/main.vitrine` строится только из `onHomeVitrine: true` по `vitrineOrder` | AC-02, FR-B-1, A-12 | 3 |
| R6 | Изменение состава/порядка витрины отражается в `home_feed` без релиза МП | AC-02 (TC-03/TC-04) | 3 |
| R7 | `sitemap_public.scenarioSlugs` поддерживается (опубликованные сценарии) | A-10b, A-10d | 3 |
| R8 | единый `home_feed` достаточен для главного экрана; черновики не читаются | A-12, A-38 | 5 |

## 3. Архитектура данных

```mermaid
flowchart TD
  subgraph SRC["Репозиторий (data/content)"]
    SCJSON[scenarios/*.json\n+ onHomeVitrine, vitrineOrder, whyTheseGames]
  end

  IMP[Скрипт импорта tools/\nвалидация + запись] -->|валидация CR-4, A-4a| SCJSON
  IMP -->|запись service account| FS[(Firestore)]

  subgraph FS["Firestore"]
    SC[scenarios — источник правды, закрыт\nwhyTheseGames, onHomeVitrine, vitrineOrder]
    SP[scenario_public/{scenarioId}\n+ whyTheseGames]
    HF[home_feed/main — .vitrine]
    SM[sitemap_public/main — .scenarioSlugs]
  end

  SC -->|публикация A-10| SP
  SC -->|only published + onHomeVitrine\nпо vitrineOrder A-12| HF
  SC -->|all published slug| SM

  HF -->|read A-38| MP[МП / Flutter — главный экран]
```

**Ключевые решения:**

* **Канал эксперта — импорт из репозитория** (**ED-4**): JSON сценария в `data/content/scenarios/` несёт `whyTheseGames`, `onHomeVitrine`, `vitrineOrder`; скрипт валидирует, записывает источник правды `scenarios/{id}`, публикует `scenario_public` и обновляет `home_feed`/`sitemap_public`. Отдельная админка не строится.

* **Обоснование —** на уровне **сценария целиком** (**CR-4**), не в связи сценарий–игра; попадает в `scenario_public.whyTheseGames`. Поле **обязательно при публикации** (**A-30**).

* **Витрина — данные сценария.** `home_feed.main.vitrine` формируется из **источника правды** `scenarios` (с фильтром `published && onHomeVitrine`), сортировка по `vitrineOrder`. `onHomeVitrine`/`vitrineOrder` остаются в источнике и **не дублируются** в публичные документы сценария (**SP-E0-01 §4.7**).

* **`ScenarioCard` в `vitrine`**: `{ scenarioId, slug, title, subtitle, imageRef, alt }` (**SP-E0-01 §4.2**). `imageRef`/`alt` — опционально из первого `teaser`-слайда первой игры сценария (по `order` связки); при отсутствии — поля опускаются (схема допускает, `imageRef`/`alt` необязательны).

* **Денормализация и версионирование**: при каждом обновлении `home_feed`/`sitemap_public` инкрементируется `contentVersion` и обновляется `updatedAt` (**A-44**), чтобы клиент инвалидировал кэш без релиза (**FR-M-3**, E2).

## 4. Шаги (в порядке зависимостей)

### Шаг 1. Подтвердить схему сценария и витрины

Источник правды — **СТ §4.2** и **SP-E0-01 §4.2/§4.4**; артефакт — `docs/product/schemas/content-contract.schema.json` (уже содержит `scenarioPublic` и `homeFeed`/`scenarioCard`).

Документ `scenarios/{id}` (источник правды, закрыт) — релевантные поля:

| Поле | Тип | Обяз. | Комментарий |
| --- | --- | --- | --- |
| `whyTheseGames` | string (plain text) | да* | Обоснование (**CR-4**); переносы `\n` допускаются, без Markdown/HTML (**A-4a**) |
| `published` | bool | да | Черновик/опубликовано (**A-4b**) |
| `onHomeVitrine` | bool | да | Редакционная витрина (**FR-B-1**) |
| `vitrineOrder` | number | нет | Порядок на главной витрине; **если** `onHomeVitrine` — ожидается |

\* Обязателен в интерпретации валидатора (см. Шаг 2); публикация невозможна без заполненного обоснования (**A-30**).

Публичное представление `scenario_public/{scenarioId}.whyTheseGames` — `string (plain text)`, обязателен (**SP-E0-01 §4.4**).

Публичная витрина `home_feed/main.vitrine` — `array<ScenarioCard>` где `ScenarioCard = { scenarioId, slug, title, subtitle?, imageRef?, alt? }` (**SP-E0-01 §4.2**).

### Шаг 2. Валидатор сценария — расширение (`tools/validate-scenario.mjs`)

Уже реализовано для **AC-01** (SP-E1-03): `whyTheseGames` входит в `REQUIRED_SCENARIO_FIELDS`, plain text-проверка `MARKDOWN_RE` покрывает `whyTheseGames` и тексты связок. Дополнить:

* **Витрина** (**R4**, AC-02):
  * `onHomeVitrine` — если присутствует, `boolean`; иначе по умолчанию `false`.
  * `vitrineOrder` — если присутствует, целое `≥ 1`.
  * Если `onHomeVitrine === true` и `vitrineOrder` отсутствует/не целое `≥ 1` — ошибка (порядок витрины обязателен для редакционной витрины).
  * `published === true` + `whyTheseGames` пусто — ошибка «нельзя опубликовать без whyTheseGames» (явная, на publish; текущая реализация требует всегда — это строже, соответствует AC-01; при желании мягче для черновиков — см. follow-up).

Ошибки — явные сообщения, запись не выполняется.

### Шаг 3. Скрипт импорта/публикации сценария — поддержка витрины

Место и окружение: `tools/`, Node ≥18, `firebase-admin`; переиспользует `import-scenario.mjs` (SP-E1-03) и общие утилиты.

**Расширения в `tools/import-scenario.mjs`** (после сборки `scenario_public`):

1. Валидация сценария (шаг 2) + `whyTheseGames` обязателен (уже есть).
2. Запись `scenarios/{id}` с `whyTheseGames`, `onHomeVitrine`, `vitrineOrder` (уже есть).
3. Сборка `scenario_public` с `whyTheseGames` (уже есть).
4. **`home_feed/main.vitrine`** — пересборка из всех опубликованных сценариев:
   * Прочитать все `scenarios` с `published === true` (запрос по `published`), отфильтровать `onHomeVitrine === true`, отсортировать по `vitrineOrder` (стабильность — вторичная сортировка по `id`).
   * Для каждой записи собрать `ScenarioCard` (`imageRef`/`alt` из первого `teaser` первой игры, если есть).
   * Прочитать текущий `home_feed/main`, записать поле `vitrine` (сохранив остальные поля — `carousel` управляет `import-games.mjs`), инкремент `contentVersion`, `updatedAt`.
5. **`sitemap_public/main.scenarioSlugs`** — пересчитать из всех опубликованных сценариев (`slug`), сохранив остальные поля, инкремент `contentVersion`, `updatedAt`.
6. Идемпотентность: повторный запуск с теми же данными не дублирует записи и не «сдвигает» `contentVersion` сверх фактического пересчёта только при изменении (опция сравнения с текущим значением).

Команды: `node tools/import-scenario.mjs --project dev data/content/scenarios/<id>.json [--dry-run]`; `node tools/import-all.mjs --project dev [--dry-run]` (уже объединяет игры + сценарии).

**Отдельная логика витрины** при необходимости выделяется в общий модуль `tools/home-feed.mjs` (используется и `import-games.mjs` для `carousel`, и `import-scenario.mjs` для `vitrine`), чтобы не дублировать обработку `home_feed`. Это задел под **US-E2-01**.

### Шаг 4. Публичные представления и правила read

Публичный `whyTheseGames` попадает в `scenario_public` (уже реализовано в SP-E1-03). Правила проектируются/проверяются в `scenario-site/firestore.rules` (**SP-E0-01**): `scenarios` — закрыт (`allow read, write: if false`); `home_feed`, `sitemap_public` — `allow read: if true; allow write: if false`. В этой стори:

* эмулятор-тесты правил (расширение `scenario-site/scripts/tc-rules.mjs`): read `scenarios/{id}` → denied; read `home_feed/main` → ok (**A-38**).

* деплой в прод — **ADR-011** (блокер публичного read в проде).

### Шаг 5. тесты

| TC | Слой | Проверка | Где |
| --- | --- | --- | --- |
| TC-01 | integration | Publish без `whyTheseGames` запрещён (валидация пути) | unit-тест валидатора + импорт `--dry-run` (инвалидная фикстура) |
| TC-02 | integration | `whyTheseGames` сохраняется как plain text с переносами в `scenario_public` | импорт на dev + snapshot (сравнение `\n`) |
| TC-03 | integration | `home_feed.vitrine` содержит сценарии с `onHomeVitrine:true` в порядке `vitrineOrder` | импорт всех фикстур + diff-снапшот `home_feed/main` |
| TC-04 | integration | изменение `vitrineOrder`/состава витрины отражается в `home_feed`; `contentVersion` растёт | повторный импорт + diff |

Существующие контрактные тесты `scenario/test/contract_test.dart` (strict parse `HomeFeed`/`ScenarioPublic`, enum-ключи, round-trip) — база для TC-02/TC-03. **Smoke** — TC-02, TC-03; полный регресс — TC-01–TC-04 при изменении FR-B-1/агрегата витрины.

Локальный прогон на dev: `node tools/import-all.mjs --project dev [--dry-run]` — валидирует и импортирует все фикстуры (`data/content/games` + `scenarios`) без секретов; либо `npm run import:dev`.

## 5. Файлы

* `docs/product/specs/e1-expert-scenario-why-these-games.md` — **настоящий документ** (SP-E1-02).

* `docs/product/schemas/content-contract.schema.json` — контракт (уже содержит `scenarioPublic`, `homeFeed`, `scenarioCard`).

* `tools/validate-scenario.mjs` — валидатор сценария (расширение: витрина).

* `tools/import-scenario.mjs` — скрипт импорта/публикации сценария (расширение: `home_feed.vitrine`, `sitemap.scenarioSlugs`).

* `tools/import-games.mjs` — импорт игры (уже поддерживает `home_feed.carousel`; при выделении общего модуля — рефакторинг без изменения поведения).

* (опц.) `tools/home-feed.mjs` — общий модуль сборки `home_feed` (задел под US-E2-01).

* `data/content/scenarios/*.json` — фикстуры (`semya`, `vecherinka` уже имеют `onHomeVitrine`/`vitrineOrder`; `data/content/scenarios/invalid/` — негативные, в т.ч. без `whyTheseGames` и с дублем `vitrineOrder`).

* `scenario-site/firestore.rules` — правила (существуют; деплой ADR-011).

* `scenario-site/scripts/tc-rules.mjs` — эмулятор-тесты правил (расширение).

* `scenario/lib/data/aggregates/aggregate_repository.dart` — репозиторий чтения (существует; `HomeFeed` читается через `fetchHomeFeed`).

* `scenario/test/contract_test.dart` — контрактные тесты (существуют).

## 6. Риски

* **`home_feed/main.vitrine` не собирается нигде** на текущий момент: `import-scenario.mjs` не трогает `home_feed` (только `scenario_public`/`game_public`); `import-games.mjs` трогает только `carousel`. Митиг: шаг 3 добавляет пересборку `vitrine`/`scenarioSlugs`; TC-03/TC-04 закрывают расхождение.

* **Совместное владение `home_feed/main`** игровым и сценарным скриптами (одна запись, разные поля). Митиг: запись по полям (read–modify–write сохраняет `carousel` из игр и `vitrine` из сценариев), общий модуль для `contentVersion`. Остаточный риск гонки при параллельном импорте — снижается `--dry-run` и идемпотентностью.

* **Источник `imageRef` сценария** в `ScenarioCard` не определён в СТ (у сценария нет поля изображения). Митиг: правило «первый `teaser`-слайд первой игры»; при появлении отдельного изображения сценария — обновить схему/сборщик (задел).

* **Деплой правил в прод отложен до ADR-011** — до деплоя Firestore закрыт, публичный read в проде невозможен. Митиг: приёмка в эмуляторе; деплой — отдельная задача.

## 7. Follow-up (вне scope)

* Деплой Firestore Rules/Storage — **ADR-011**.

* Главный экран МП и чтение `home_feed` — **US-E2-01** (задел: общий модуль сборки `home_feed`).

* группы смысла и «Сценарии прошлого» — **E7** (в `home_feed.groups` — пусто на MVP).

* Поля шаринга/SEO сценария — **US-E1-04**.

* смягчение валидации `whyTheseGames` для черновиков (отвязать от публикации) — опционально, если нужны черновики без обоснования.

## 8. Доступы и блокеры

* Доступ к Firebase dev `scenario-ba26a` / prod `scenario-prod-491c` и Supabase `service_role` (вне репозитория) для импорта.

* Согласование имён коллекций/агрегатов и логики сборки `home_feed` — **ADR-010**; деплой правил — **ADR-011**.

* **A-40**: секреты — только env/Secret Manager, не в git.

## 9. Verify

Соответствие критериям приёмки **US-E1-02**:

* **AC-01 (FR-B-1, CR-4; A-4a)** — TC-01/TC-02: `whyTheseGames` обязателен при публикации; после неё в `scenario_public.whyTheseGames` — корректный plain text с сохранёнными переносами.

* **AC-02 (FR-B-1)** — TC-03/TC-04: при заданных `onHomeVitrine`/`vitrineOrder` после публикации `home_feed/main.vitrine` отражает состав и порядок витрины; главный экран МП строится только из `home_feed` без релиза приложения; изменение порядка витрины при републикации обновляет агрегат.

Критерий готовности: импорт валидного сценария (с `why`, витриной и порядком) на dev проходит end-to-end; `home_feed`/`scenario_public` соответствуют JSON Schema; TC-01–TC-04 зелёные.

## 10. История изменений

| Дата | Автор | Изменение |
| --- | --- | --- |
| 2026-09-07 | AID | Первая версия (drafted). `whyTheseGames` (plain text, публикация) + витрина (`home_feed.vitrine`/`sitemap_public.scenarioSlugs`) по FR-B-1/CR-4 и A-12; расширение валидатора и импортера. |