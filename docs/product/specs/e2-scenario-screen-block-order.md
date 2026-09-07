---
spec_id: SP-E2-02
title: "Спецификация реализации: экран сценария — порядок блоков (обоснование → список игр)"
story_id: US-E2-02
status: approved
updated: "2026-09-07"
---
# Спецификация реализации — US-E2-02 «Экран сценария: порядок блоков (обоснование → список игр)»

## 1. Scope

**В объёме:**

* **Экран сценария** в МП: блок «почему эти игры подходят» (`whyTheseGames`) выше списка игр (**FR-M-2**, версия 0.9+ БТ, **AC-01**).

* **Список игр** сценария в порядке из данных (`ScenarioPublic.games`) (**FR-M-2**, **AC-01**).

* **Сохранение переносов строк** в `whyTheseGames` (plain text с `\n`) (**A-4a**, **AC-02**).

* **Чтение данных** через `AggregateRepository.getScenario(scenarioId)` из `scenario_public/{scenarioId}` (**A-11**, **A-38**).

* **Навигация** из списка игр на экран игры (**US-E2-03**) — переход с передачей `gameId` и `scenarioId`.

* **Тесты**: widget-тесты экрана (AC-01, AC-02).

**Вне scope:**

* Редактирование контента (E1).

* Аналитика block_view — **US-E6-03** (отдельная стори).

* Экран игры — **US-E2-03** (реализован; здесь только переход на него).

* Главный экран/витрина — **US-E2-01**.

## 2. Требования → шаги

| #  | Требование                                                      | Источник          | Шаги |
| -- | --------------------------------------------------------------- | ----------------- | ---- |
| R1 | Блок обоснования выше списка игр                                | AC-01, FR-M-2     | 2    |
| R2 | Список игр в порядке из данных сценария                         | AC-01, FR-M-2     | 3    |
| R3 | Переносы строк в `whyTheseGames` сохраняются                    | AC-02, A-4a       | 2    |
| R4 | Чтение `scenario_public/{scenarioId}` через репозиторий         | A-11, A-38        | 1    |
| R5 | Переход на экран игры с `gameId`/`scenarioId`                   | US-E2-03          | 3    |

## 3. Архитектура данных

```mermaid
flowchart TD
  subgraph FS["Firestore"]
    SP[scenario_public/{scenarioId}]
  end

  subgraph MP["МП / Flutter"]
    REP[AggregateRepository.getScenario]
    SCR[Экран сценария]
    WHY[Блок whyTheseGames]
    GAMES[Список ScenarioGameRef]
    GAME[Экран игры US-E2-03]
  end

  SP -->|read A-38| REP
  REP --> SCR
  SCR --> WHY
  SCR --> GAMES
  GAMES -->|gameId, scenarioId| GAME
```

**Ключевые решения:**

* **Источник — `scenario_public/{scenarioId}`** (**A-11**, **A-38**): экран читает публичный агрегат через `AggregateRepository.getScenario`; черновики недоступны клиенту.

* **Порядок блоков** (**FR-M-2**, версия 0.9+): сначала `whyTheseGames`, затем список игр `games` в порядке из данных (**AC-01**).

* **Plain text с переносами** (**A-4a**): `whyTheseGames` — plain text; переносы `\n` сохраняются визуально (**AC-02**).

* **Переход на игру** (**US-E2-03**): тап по игре открывает `GameScreen` с `gameId` и `scenarioId` (контекст описания).

## 4. Шаги (в порядке зависимостей)

### Шаг 1. Чтение данных через репозиторий

* `AggregateRepository.getScenario(scenarioId)` уже реализован (`FirestoreAggregateRepository`, SP-E0-01). Экран получает `ScenarioPublic` по `scenarioId`.

* Навигация: экран сценария открывается из витрины (**US-E2-01**) с передачей `scenarioId`.

* **Реализовано:** `scenario/lib/features/scenario/scenario_screen.dart` — `ScenarioScreen` (StatefulWidget), читает `scenario_public/{scenarioId}` через инжектируемый `AggregateRepository`.

### Шаг 2. Блок обоснования (AC-01, AC-02)

* Блок `whyTheseGames` отображается **выше** списка игр (**FR-M-2**).

* Текст — plain text с сохранением переносов `\n` (**A-4a**, **AC-02**).

* **Реализовано:** блок обоснования в `_ScenarioContent` выше списка игр; `Text(whyTheseGames)` сохраняет переносы.

### Шаг 3. Список игр и переход (AC-01, R5)

* Список `ScenarioPublic.games` (`List<ScenarioGameRef>`) в порядке из данных.

* Каждая игра: `title`, при наличии `imageRef` — превью через `supabasePublicUrl(imageRef)` (**A-39**).

* Тап по игре → `GameScreen(gameId, scenarioId)` (**US-E2-03**).

* **Реализовано:** `_GameTile` (ListTile) с превью и тапом; переход — через инжектируемый `onOpenGame(gameId, scenarioId)`.

### Шаг 4. Тесты

| AC    | Слой  | Проверка                                             | Где                          |
| ----- | ----- | ---------------------------------------------------- | ---------------------------- |
| AC-01 | widget | Обоснование выше списка игр; порядок из данных       | widget-тест экрана           |
| AC-02 | widget | Переносы строк в `whyTheseGames` сохраняются         | widget-тест экрана           |

* Widget-тесты с фейковым `AggregateRepository` (по образцу `test/game_screen_test.dart`).

* **Реализовано:** `scenario/test/scenario_screen_test.dart` — 2 теста (AC-01, AC-02).

## 5. Файлы

* `docs/product/specs/e2-scenario-screen-block-order.md` — **настоящий документ** (SP-E2-02).

* `scenario/lib/features/scenario/scenario_screen.dart` — экран сценария (реализовано).

* `scenario/lib/data/contract/models.dart` — `ScenarioPublic`, `ScenarioGameRef` (существуют, контракт не меняется).

* `scenario/lib/data/firestore/aggregate_repository.dart` — `getScenario` (существует).

* `scenario/lib/features/game/game_screen.dart` — `GameScreen` (существует, US-E2-03).

* `scenario/test/scenario_screen_test.dart` — widget-тесты экрана (реализовано).

## 6. Риски

* **Навигация из витрины** (**US-E2-01**) — экран сценария открывается оттуда. Митиг: экран принимает `scenarioId` как параметр.

* **Переход на игру** — зависит от готовности `GameScreen` (**US-E2-03**, реализован). Митиг: навигация через `Navigator.push` с `gameId`/`scenarioId`.

* **Отсутствие `imageRef`** у игры — превью не показывается, остаётся заглушка. Митиг: опциональное поле, рендер без изображения.

## 7. Follow-up (вне scope)

* Главный экран/витрина — **US-E2-01**.

* Аналитика block_view — **US-E6-03**.

* Офлайн-доступ — **US-E2-05**; обновление контента — **US-E2-04**.

## 8. Доступы и блокеры

* Зависимость от витрины (**US-E2-01**) для навигации.

* **A-40**: секреты — только env/Secret Manager, не в git.

## 9. Verify

Соответствие критериям приёмки **US-E2-02**:

* **AC-01 (FR-M-2)** — при скролле сверху вниз сначала блок обоснования, ниже список игр в порядке из данных (widget-тест).

* **AC-02 (A-4a)** — переносы строк в `whyTheseGames` сохраняются визуально (widget-тест).

Критерий готовности: экран сценария рендерит обоснование → список игр из `scenario_public`; widget-тесты AC-01..AC-02 зелёные.

## 10. История изменений

| Дата       | Автор | Изменение                                                                                                                          |
| ---------- | ----- | ---------------------------------------------------------------------------------------------------------------------------------- |
| 2026-09-07 | AID   | Первая версия (drafted). Экран сценария из `scenario_public` (A-11/A-38): обоснование → список игр (FR-M-2), переносы строк (A-4a), переход на экран игры (US-E2-03). |
| 2026-09-07 | AID   | Реализован экран сценария (`lib/features/scenario/scenario_screen.dart`): обоснование → список игр, переход на игру; widget-тесты AC-01..AC-02 (`test/scenario_screen_test.dart`). |