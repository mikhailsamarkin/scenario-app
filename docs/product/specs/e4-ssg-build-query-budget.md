---
spec_id: SP-E4-04
title: "Спецификация реализации: предсказуемый билд SSG — бюджет запросов к Firestore"
story_id: US-E4-04
status: drafted
updated: "2026-09-08"
---
# Спецификация реализации — US-E4-04 «Предсказуемый билд SSG: бюджет запросов к Firestore»

## 1. Scope

**В объёме:**

* **Пайплайн сборки Next.js** из опубликованных данных через агрегаты (**A-10**, **E0**).

* **Бюджет запросов** к Firestore на сгенерированный URL — ориентир **A-10b** (1–2 чтения на URL).

* **Триггер билда** — **ED-10** (workflow_dispatch).

* **Измерение** числа чтений в CI для регрессий.

**Вне scope:**

* ISR по расписанию (**ED-10**).

## 2. Требования → шаги

| #  | Требование                                                        | Источник          | Шаги |
| -- | ----------------------------------------------------------------- | ----------------- | ---- |
| R1 | Билд из агрегатов, без N+1                                        | AC-01, A-10b      | 1    |
| R2 | Бюджет чтений на URL (1–2)                                        | AC-01, A-10b      | 2    |
| R3 | Триггер workflow_dispatch                                         | AC-02, ED-10      | 3    |

## 3. Архитектура данных

```mermaid
flowchart TD
  subgraph FS["Firestore"]
    SM[sitemap_public/main]
    SP[scenario_public/{id}]
    GP[game_public/{id}]
  end

  subgraph CI["GitHub Actions"]
    WF[workflow_dispatch]
    BUILD[next build]
    METRIC[Логирование числа чтений]
  end

  WF --> BUILD
  BUILD -->|1 чтение| SM
  BUILD -->|1 чтение на URL| SP
  BUILD -->|1 чтение на URL| GP
  BUILD --> METRIC
```

**Ключевые решения:**

* **Без N+1** (**A-10b**, **A-10d**): `generateStaticParams` читает один `sitemap_public/main`; каждая страница — один документ.

* **Измерение**: логирование числа чтений в билде; сравнение с бюджетом в CI.

* **Триггер** (**ED-10**): `workflow_dispatch` для полного rebuild.

## 4. Шаги (в порядке зависимостей)

### Шаг 1. Пайплайн сборки

* GitHub Actions workflow: `next build` (SSG) из опубликованных данных.

* **Реализовано:** `.github/workflows/build.yml` — `workflow_dispatch`, `npm ci`, `npm run build` с Firebase/Supabase env из секретов.

* **Исправлен предсуществующий баг билда:** папка `scenarios/[id]` переименована в `scenarios/[slug]` (параметр `generateStaticParams` должен совпадать с именем папки). Билд теперь генерирует страницы из sitemap.

* **Блокер:** секреты `NEXT_PUBLIC_FIREBASE_*`/`NEXT_PUBLIC_SUPABASE_*` в GitHub.

### Шаг 2. Бюджет запросов

* Логирование числа чтений на URL; проверка против ориентира **A-10b**.

* **Частично:** `generateStaticParams` читает один `sitemap_public/main`; страница — один документ (без N+1, A-10b/A-10d). Измерение в CI — follow-up.

### Шаг 3. Триггер

* `workflow_dispatch` для полного rebuild (**ED-10**).

* **Реализовано:** `on.workflow_dispatch` в `build.yml`.

### Шаг 4. Тесты

| AC    | Слой  | Проверка                                             | Где                          |
| ----- | ----- | ---------------------------------------------------- | ---------------------------- |
| AC-01 | integration | Число чтений на URL ≤ ориентира                     | CI-метрика                   |
| AC-02 | integration | workflow_dispatch запускает полный rebuild          | CI                           |

## 5. Файлы

* `docs/product/specs/e4-ssg-build-query-budget.md` — **настоящий документ** (SP-E4-04).

* `scenario-site/.github/workflows/build.yml` — пайплайн сборки (предлагается).

* `scenario-site/scripts/build-metrics.mjs` — измерение чтений (предлагается).

## 6. Риски

* **N+1 при билде** — митиг: агрегаты + измерение в CI (**A-10b**).

* **Нет доступа к Firebase при билде** — блокер. Митиг: service account в секретах.

## 7. Follow-up (вне scope)

* ISR по расписанию (**ED-10**).

## 8. Доступы и блокеры

* **Блокер:** доступ к Firebase (service account) для чтения агрегатов.

* **A-40**: секреты — только env/Secret Manager, не в git.

## 9. Verify

Соответствие критериям приёмки **US-E4-04**:

* **AC-01 (A-10b)** — число чтений на URL ≤ ориентира (CI-метрика).

* **AC-02 (ED-10)** — workflow_dispatch запускает полный rebuild (CI).

Критерий готовности: пайплайн сборки из агрегатов с бюджетом запросов и триггером workflow_dispatch.

## 10. История изменений

| Дата       | Автор | Изменение |
| ---------- | ----- | --------- |
| 2026-09-08 | AID   | Первая версия (drafted). Пайплайн сборки, бюджет запросов, триггер. |
| 2026-09-08 | AID   | Реализовано: `build.yml` (workflow_dispatch + next build + env из секретов). Бюджет-метрика в CI — follow-up. |