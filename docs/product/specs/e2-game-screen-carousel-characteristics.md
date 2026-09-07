---
spec_id: SP-E2-03
title: "Спецификация реализации: экран игры — карусель, характеристики, краткое описание в контексте сценария"
story_id: US-E2-03
status: approved
updated: "2026-09-07"
---
# Спецификация реализации — US-E2-03 «Экран игры: карусель, характеристики, краткое описание в контексте сценария»

## 1. Scope

**В объёме:**

* **Экран игры** в МП, открываемый из сценария: карусель изображений, четыре характеристики, краткое описание в контексте сценария (**FR-M-2**, **CR-4.1**, **CR-5**).

* **Карусель** по слайдам `GamePublic.carousel` (**CR-5**): типы кадров и порядок из данных; `alt` выводится где задано (**AC-01**).

* **Четыре характеристики** из enum-полей игры: `playersHint`, `durationBucket`, `ageHint`, `rulesComplexity` (**CR-4.1**, **AC-02**).

* **Краткое описание** `shortDescription` из связки сценарий–игра (`GameScenarioRef`), соответствующей открытому сценарию (**FR-M-2**, **A-12**, **AC-03**).

* **Чтение данных** через `AggregateRepository.getGame(gameId)` из `game_public/{gameId}` (**A-11**, **A-38**).

* **Тесты**: widget-тесты экрана (AC-01..AC-03).

**Вне scope:**

* Производительность карусели и кэш изображений — **US-E2-06** (здесь — только отображение; кэш подключается в US-E2-06).

* Офлайн-доступ и Firestore persistence — **US-E2-05**.

* Обновление контента при сети — **US-E2-04**.

* Экран сценария и блок «почему эти игры подходят» — **US-E2-02** (обоснование на уровне сценария, **CR-4**).

* Вёрстка сайта (страница игры) — эпик **E4**.

## 2. Требования → шаги

| #  | Требование                                                              | Источник                | Шаги |
| -- | ----------------------------------------------------------------------- | ----------------------- | ---- |
| R1 | Карусель с валидными типами слайдов и alt где задано                    | AC-01, CR-5             | 2    |
| R2 | Четыре характеристики из контракта (enum)                               | AC-02, CR-4.1           | 3    |
| R3 | Краткое описание в контексте открытого сценария                         | AC-03, FR-M-2, A-12     | 4    |
| R4 | Чтение `game_public/{gameId}` через репозиторий                         | A-11, A-38              | 1    |
| R5 | Не подставлять описание из другого сценария                             | ED-9                    | 4    |

## 3. Архитектура данных

```mermaid
flowchart TD
  subgraph FS["Firestore"]
    GP[game_public/{gameId}]
  end

  subgraph MP["МП / Flutter"]
    REP[AggregateRepository.getGame]
    SCR[Экран игры]
    CAR[Карусель: GamePublic.carousel]
    CH[Характеристики: 4 enum-поля]
    DESC[shortDescription из GameScenarioRef]
  end

  GP -->|read A-38| REP
  REP --> SCR
  SCR --> CAR
  SCR --> CH
  SCR --> DESC
```

**Ключевые решения:**

* **Источник — `game_public/{gameId}`** (**A-11**, **A-38**): экран читает публичный агрегат через `AggregateRepository.getGame`; черновики недоступны клиенту.

* **Карусель по контракту** (**CR-5**): `GamePublic.carousel` — `List<Slide>` с `imageRef`, `frameType`, `caption?`, `alt?`; порядок и типы из данных. Публичный URL изображения — `supabasePublicUrl(imageRef)` (**A-39**, **ED-14**).

* **Характеристики — enum-поля** (**CR-4.1**): `playersHint`, `durationBucket`, `ageHint`, `rulesComplexity`; подписи на русском — из `uiLabel` enum (**ED-2**).

* **Описание в контексте сценария** (**A-12**, **ED-9**): `GameScenarioRef.shortDescription` из `GamePublic.scenarios`, где `scenarioId` совпадает с открытым сценарием; описание из другого сценария не подставляется.

## 4. Шаги (в порядке зависимостей)

### Шаг 1. Чтение данных через репозиторий

* `AggregateRepository.getGame(gameId)` уже реализован (`FirestoreAggregateRepository`, SP-E0-01). Экран получает `GamePublic` по `gameId`.

* Навигация: экран игры открывается из сценария с передачей `gameId` (и `scenarioId` для контекста описания).

* **Реализовано:** `scenario/lib/features/game/game_screen.dart` — `GameScreen` (StatefulWidget), читает `game_public/{gameId}` через инжектируемый `AggregateRepository` (для тестов — фейк).

### Шаг 2. Карусель (AC-01)

* Виджет карусели по `GamePublic.carousel` (**CR-5**): каждый слайд — `Slide` с `imageRef` → `supabasePublicUrl(imageRef)` (**A-39**), `frameType` и `alt` где задано.

* Порядок и типы кадров — из данных; минимум один слайд `teaser` гарантирован контрактом (SP-E1-01).

* Изображения — через кэшируемый виджет (**US-E2-06**); на момент этой стори допустим прямой `Image.network` с placeholder, кэш подключается в US-E2-06.

* **Реализовано:** карусель `_Carousel` (PageView) в `game_screen.dart`; изображение слайда — через инжектируемый `slideImageBuilder` (по умолчанию `CachedNetworkImageWidget` из US-E2-06), alt выводится где задано.

### Шаг 3. Четыре характеристики (AC-02)

* Блок характеристик из `playersHint`, `durationBucket`, `ageHint`, `rulesComplexity` (**CR-4.1**).

* Подписи на русском — из `uiLabel` enum (`PlayersHint`, `AgeHint`) и фиксированных подписей для `DurationBucket`/`RulesComplexity` (**ED-2**).

* **Реализовано:** `_Characteristics` в `game_screen.dart` + хелперы `durationBucketLabel`/`rulesComplexityLabel`.

### Шаг 4. Краткое описание в контексте сценария (AC-03)

* Из `GamePublic.scenarios` найти `GameScenarioRef` с `scenarioId == открытый сценарий`; показать его `shortDescription` (**A-12**).

* Если связка не найдена — описание не показывается (не подставлять из другого сценария, **ED-9**).

* **Реализовано:** поиск `GameScenarioRef` по `scenarioId` в `_GameContent`; при отсутствии связки блок не выводится.

### Шаг 5. Тесты

| AC    | Слой  | Проверка                                             | Где                          |
| ----- | ----- | ---------------------------------------------------- | ---------------------------- |
| AC-01 | widget | Карусель показывает слайды по контракту, alt где задано | widget-тест экрана           |
| AC-02 | widget | Четыре характеристики из enum-полей                  | widget-тест экрана           |
| AC-03 | widget | shortDescription из связки открытого сценария        | widget-тест экрана           |

* Widget-тесты с фейковым `AggregateRepository` (по образцу `test/contract_test.dart`): рендер `GamePublic` с каруселью, характеристиками и `GameScenarioRef`.

* **Реализовано:** `scenario/test/game_screen_test.dart` — 4 теста (AC-01..AC-03 + ED-9). Изображение слайда подставляется заглушкой через `slideImageBuilder`, чтобы не зависеть от плагина дискового кэша.

## 5. Файлы

* `docs/product/specs/e2-game-screen-carousel-characteristics.md` — **настоящий документ** (SP-E2-03).

* `scenario/lib/features/game/game_screen.dart` — экран игры, карусель, характеристики (реализовано).

* `scenario/lib/cache/cached_network_image_widget.dart` — кэшируемое изображение слайда (US-E2-06, реализовано).

* `scenario/lib/data/contract/models.dart` — `GamePublic`, `Slide`, `GameScenarioRef` (существуют, контракт не меняется).

* `scenario/lib/data/firestore/aggregate_repository.dart` — `getGame` (существует).

* `scenario/lib/supabase_config.dart` — `supabasePublicUrl` (существует).

* `scenario/test/game_screen_test.dart` — widget-тесты экрана (реализовано).

## 6. Риски

* **Кэш изображений подключён** (**US-E2-06**): слайды рендерятся через `CachedNetworkImageWidget`; в тестах — заглушка через `slideImageBuilder`.

* **Описание связки отсутствует** — экран без `shortDescription`. Митиг: не показывать блок (ED-9), не подставлять чужое.

* **Навигация из сценария** — передача `gameId`/`scenarioId` зависит от экрана сценария (**US-E2-02**). Митиг: экран принимает оба id как параметры.

## 7. Follow-up (вне scope)

* Кэш изображений и производительность карусели — **US-E2-06**.

* Офлайн-доступ — **US-E2-05**; обновление контента — **US-E2-04**.

* Страница игры на сайте — эпик **E4**.

## 8. Доступы и блокеры

* Зависимость от экрана сценария (**US-E2-02**) для навигации.

* **A-40**: секреты — только env/Secret Manager, не в git.

## 9. Verify

Соответствие критериям приёмки **US-E2-03**:

* **AC-01 (FR-M-2, CR-5)** — карусель отображает слайды с валидными типами и alt где задано (widget-тест).

* **AC-02 (CR-4.1)** — четыре характеристики из контракта (widget-тест).

* **AC-03 (FR-M-2)** — `shortDescription` из связки открытого сценария (widget-тест).

Критерий готовности: экран игры рендерит карусель, характеристики и описание из `game_public`; widget-тесты AC-01..AC-03 зелёные.

## 10. История изменений

| Дата       | Автор | Изменение                                                                                                                          |
| ---------- | ----- | ---------------------------------------------------------------------------------------------------------------------------------- |
| 2026-09-07 | AID   | Первая версия (drafted). Экран игры из `game_public` (A-11/A-38): карусель CR-5, характеристики CR-4.1, описание в контексте сценария A-12/ED-9. |
| 2026-09-07 | AID   | Реализован экран игры (`lib/features/game/game_screen.dart`): карусель, характеристики, описание; widget-тесты AC-01..AC-03 + ED-9 (`test/game_screen_test.dart`). Изображение — через `CachedNetworkImageWidget` (US-E2-06). |