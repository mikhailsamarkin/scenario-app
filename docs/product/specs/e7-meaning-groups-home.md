---
spec_id: SP-E7-01
title: "Спецификация реализации: группы смысла на главном экране"
story_id: US-E7-01
status: approved
updated: "2026-09-08"
---
# Спецификация реализации — US-E7-01 «Группы смысла на главном экране»

## 1. Scope

**В объёме:**

* **Группы смысла** на главном экране, конфигурируемые данными (**БТ §7.1**, **FR-M-1**).

* **Экран группы**: список сценариев группы (**AC-02**).

* **Данные**: фикстуры групп, поле группы у сценария, импорт в агрегаты (**AC-01**).

* **Тесты**: unit-тесты импорта/валидации; widget-тесты home и экрана группы.

**Вне scope:**

* Редизайн по Figma — **US-E9-01** (категории = группы смысла, но UI — отдельно).

* «Сценарии прошлого» — **US-E7-02**.

## 2. Требования → шаги

| #  | Требование                                                        | Источник          | Шаги |
| -- | ----------------------------------------------------------------- | ----------------- | ---- |
| R1 | Группы задаются данными (не хардкод)                             | AC-01, БТ §7.1    | 1–2  |
| R2 | Группы видны на главном экране, состав с сервера                 | AC-01, FR-M-1     | 3    |
| R3 | Тап по группе → экран группы со сценариями                       | AC-02            | 4    |

## 3. Архитектура данных

```mermaid
flowchart TD
  subgraph FS["Firestore"]
    SG[semantic_groups_public/{id}]
    SP[scenario_public/{id}]
    HF[home_feed/main]
  end

  subgraph MP["МП / Flutter"]
    HOME[HomeScreen]
    GROUP[GroupScreen]
  end

  SG -->|scenarios| GROUP
  HF -->|groups| HOME
  HOME -->|tap| GROUP
  SP -->|semanticGroupIds| GROUP
```

**Ключевые решения:**

* **Контракт уже есть** (**E0**): `SemanticGroupPublic`, `GroupRef`, `home_feed.groups`, `scenario_public.semanticGroupIds`.

* **Импорт**: новый `tools/import-groups.mjs` — пишет `semantic_groups_public/{id}` и заполняет `home_feed.groups`.

* **UI**: `GroupScreen` читает `semantic_groups_public/{id}` через `getSemanticGroup` (уже в репозитории).

## 4. Шаги (в порядке зависимостей)

### Шаг 1. Данные групп

* Фикстуры `data/content/groups/*.json` (id, title, slug, scenarios[]).

* Поле группы у сценария: `semanticGroupIds` в `data/content/scenarios/*.json`.

* **Реализовано:** `data/content/groups/` — `vdvoem.json`, `s-detmi.json`, `bolshaya-kompaniya.json`; `semanticGroupIds` добавлен в `semya.json`, `vecherinka.json`.

### Шаг 2. Импорт групп

* `tools/import-groups.mjs`: пишет `semantic_groups_public/{id}` (список ScenarioCard) и `home_feed.groups` (GroupRef).

* Валидация: обязательность title/slug, ссылочная целостность сценариев.

* **Реализовано:** `tools/import-groups.mjs`, `tools/validate-group.mjs` + unit-тесты; `semanticGroupIds` в `validate-scenario.mjs` и `import-scenario.mjs`.

### Шаг 3. Home: отображение групп

* `home_screen.dart`: рендер `home_feed.groups` (список групп) под витриной.

* Переход на экран группы через `onOpenGroup`.

* **Реализовано:** `home_screen.dart` — секция «Подборки» + `_GroupTile`; `onOpenGroup` в `app.dart`.

### Шаг 4. Экран группы

* `group_screen.dart`: читает `semantic_groups_public/{id}` через `getSemanticGroup`, рендерит сценарии.

* Переход на сценарий через `onOpenScenario`.

* **Реализовано:** `lib/features/group/group_screen.dart` + маршрут `_GroupRoute` в `app.dart`.

### Шаг 5. Тесты

| AC    | Слой  | Проверка                                             | Где                          |
| ----- | ----- | ---------------------------------------------------- | ---------------------------- |
| AC-01 | unit    | Группы из данных; состав с сервера                   | валидатор/импорт             |
| AC-01 | widget  | Home показывает группы из `home_feed.groups`         | widget-тест home             |
| AC-02 | widget  | Тап по группе → экран группы со сценариями           | widget-тест group            |

## 5. Файлы

* `docs/product/specs/e7-meaning-groups-home.md` — **настоящий документ** (SP-E7-01).

* `data/content/groups/*.json` — фикстуры групп (предлагается).

* `tools/import-groups.mjs` — импорт групп (предлагается).

* `tools/validate-group.mjs` — валидатор (предлагается).

* `lib/features/home/home_screen.dart` — отображение групп (предлагается).

* `lib/features/group/group_screen.dart` — экран группы (предлагается).

* `test/group_screen_test.dart` — widget-тесты (предлагается).

## 6. Риски

* **Группы без сценариев** — пустой экран. Митиг: скрывать пустые группы.

* **Ссылочная целостность** — сценарий в группе, но не опубликован. Митиг: валидация при импорте.

* **Регресс home** — митиг: widget-тесты.

## 7. Follow-up (вне scope)

* Редизайн групп по Figma — **US-E9-01**.

* «Сценарии прошлого» — **US-E7-02**.

## 8. Доступы и блокеры

* Данные **E1**, контракт **E0** (уже есть).

* **A-40**: секреты — только env/Secret Manager, не в git.

## 9. Verify

Соответствие критериям приёмки **US-E7-01**:

* **AC-01 (БТ §7.1)** — группы видны на главном, состав с сервера (widget-тест).

* **AC-02** — тап по группе → экран группы со сценариями (widget-тест).

Критерий готовности: данные групп, импорт, отображение на home и экран группы реализованы; тесты зелёные.

## 10. История изменений

| Дата       | Автор | Изменение |
| ---------- | ----- | --------- |
| 2026-09-08 | AID   | Первая версия (drafted). Группы смысла: данные, импорт, home, экран группы. |
| 2026-09-08 | AID   | Реализовано: фикстуры групп, `import-groups.mjs`/`validate-group.mjs`, `semanticGroupIds` в сценариях, `GroupScreen`, секция «Подборки» на home; unit/widget-тесты. |