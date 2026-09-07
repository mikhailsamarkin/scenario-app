---
spec_id: SP-E4-01
title: "Спецификация реализации: ЧПУ и метаданные страниц сценария и игры"
story_id: US-E4-01
status: drafted
updated: "2026-09-07"
---
# Спецификация реализации — US-E4-01 «ЧПУ и метаданные страниц сценария и игры»

## 1. Scope

**В объёме:**

* **Отдельные URL** на сценарий и игру с ЧПУ (slug из данных, **ED-8** / **E1**) (**FR-W-2**, **AC-01**).

* **Метаданные** `<title>` и `description` из полей контента (`seoTitle`/`seoDescription`, **US-E1-04**) (**SR-SEO-1**, **AC-01**).

* **SSG-генерация** маршрутов из `sitemap_public/main` (без N+1, **A-10b**/**A-10d**).

* **Доступность для индексации** (**AC-02**, **SR-SEO-1**).

* **Тесты**: контрактные/unit-тесты метаданных и путей.



**Вне scope:**

* Перелинковка сценариев и игр — **US-E4-02** (реализуется отдельно).

* CTA установки приложения — **US-E4-03**.

* Бюджет запросов при билде — **US-E4-04**.

* Core Web Vitals — **US-E4-05**.

## 2. Требования → шаги

| #  | Требование                                                          | Источник                | Шаги |
| -- | ------------------------------------------------------------------- | ----------------------- | ---- |
| R1 | Отдельные URL с ЧПУ на сценарий и игру                              | AC-01, FR-W-2, ED-8      | 1–2  |
| R2 | `<title>` и `description` из `seoTitle`/`seoDescription`            | AC-01, SR-SEO-1, US-E1-04 |  ​3    |
| R3 | SSG-генерация из sitemap без N+1                                | A-10b, A-10d          | 1–2  |
| R4 | Контент доступен для индексации                                     | AC-02, SR-SEO-1         |  ​3    |

## 3. Архитектура данных

```mermaid
flowchart TD
  subgraph FS["Firestore"]
    SM[sitemap_public/main]
    SP[scenario_public/{slug}]
    GP[game_public/{slug}]
  end

  subgraph SITE["Next.js SSG"]
    PARAMS[generateStaticParams\nиз sitemap]
    SCEN[scenarios/[slug]/page.tsx]
    GAME[games/[slug]/page.tsx]
    META[generateMetadata\nseoTitle/seoDescription]
  end

  SM -->|scenarioSlugs, gameSlugs| PARAMS
  PARAMS --> SCEN
  PARAMS --> GAME
  SP -->|A-10b| SCEN
  GP -->|A-10b| GAME
  SCEN --> META
  GAME --> META
```

**Ключевые решения:**

* **ЧПУ из данных** (**ED-8**): маршруты `scenarios/[slug]` и `games/[slug]`; slug — из `sitemap_public/main` (`scenarioSlugs`, `gameSlugs`).

* **Метаданные из контента** (**US-E1-04**, **SR-SEO-1**): `generateMetadata` возвращает `title`/`description` из `seoTitle`/`seoDescription` сценария/игры; fallback — на `title`.

* **Без N+1** (**A-10b**, **A-10d**): `generateStaticParams` читает один `sitemap_public/main`; страница читает один документ (`scenario_public`/`game_public`).

## 4. Шаги (в порядке зависимостей)

### Шаг 1. Страница сценария с метаданными

* Уже есть: `scenarios/[id]/page.tsx` (SSG из sitemap, `ScenarioClient`).

* Добавить `generateMetadata` из `seoTitle`/`seoDescription` (**SR-SEO-1**).

* **Реализовано:** `generateMetadata` в `scenarios/[id]/page.tsx` (`seoTitle ?? title`, `seoDescription`).

### Шаг 2. Страница игры с метаданными

* Создать `games/[slug]/page.tsx`: `generateStaticParams` из `sitemap.gameSlugs`; `generateMetadata` из `game_public`; рендер `GameClient` (карусель, характеристики, описание).

* **Реализовано:** `games/[slug]/page.tsx` + `GameClient.tsx` (карусель, характеристики, список сценариев).

### Шаг 3. Метаданные и индексация (AC-01, AC-02

* `generateMetadata` для обеих страниц: `title` = `seoTitle ?? title`; `description` = `seoDescription` (если есть.

* Контент рендерится на сервере (SSG,, доступен для индексации (**SR-SEO-1**, **AC-02**.

* **Реализовано:** обе страницы рендерят контент на сервере (SSG) с метаданными из контента.

### Шаг 4. Тесты

| AC    | Слой  | Проверка                                             | Где                          |
| ----- | ----- | ---------------------------------------------------- | ---------------------------- |
| AC-01 | unit    | URL и метаданные из данных (slug,, seoTitle/seoDescription) | контракт-тесты               |
| AC-02 | unit    | Контент доступен для индексации (SSG)              | контракт-тесты               |

* Контракт-тесты (`contract.test.mjs`): проверка путей и наличия SEO-полей в типах.

* **Реализовано:** `tsc --noEmit` и `next lint` чисты; контракт-тесты (3) зелёные.



## 5. Файлы

* `docs/product/specs/e4-seo-urls-scenario-game.md` — **настоящий документ** (SP-E4-01.

* `scenario-site/src/app/scenarios/[id]/page.tsx` — страница сценария с `generateMetadata` (реализовано.

* `scenario-site/src/app/games/[slug]/page.tsx` + `GameClient.tsx` — страница игры (реализовано.



* `scenario-site/src/lib/contract/repository.ts`, `types.ts`, `paths.ts` — контракт (существуют.



* `scenario-site/src/lib/contract/contract.test.mjs` — контракт-тесты (существуют; расширение.



## 6. Риски

* **SEO-поля не заполнены** — fallback на `title`. Митиг: `seoTitle ?? title`; `seoDescription` опционально.



* **N+1 при билде** — патологический рост запросов. Митиг: `generateStaticParams` читает только `sitemap_public`; страница — один документ (A-10b, A-10d.



* **Хостинг/билд** — **ED-3**/**ED-10**. Митиг: деплой — отдельная задача (ADR-015.



##  ​7. Follow-up (вне scope)

* Перелинковка — **US-E4-02**.



* CTA установки — **US-E4-03**; бюджет запросов — **US-E4-04**; Core Web Vitals — **US-E4-05**.



##  ​8. Доступы и блокеры

* Данные **E1**, хостинг **ED-3**, билд **ED-10**.



* **A-40**: секреты — только env/Secret Manager, не в git.



##  ​9. Verify

Соответствие критериям приёмки **US-E4-01**:

* **AC-01 (FR-W-2, SR-SEO-1)** — при билде существуют отдельные URL с корректными title/description из данных (unit-тест.



* **AC-02** — контент доступен для индексации согласно **SR-SEO-1** (SSG-рендер на сервере, unit-тест.



Критерий готовности: страницы сценария и игры с ЧПУ и метаданными из контента; `generateMetadata` из `seoTitle`/`seoDescription`; без N+1 при билде.



##  ​10. История изменений

| Дата       | Автор | Изменение                                                                                                                          |
| ---------- | ----- | ---------------------------------------------------------------------------------------------------------------------------------- |
| 2026-09-07 | AID   | Первая версия (drafted]. ЧПУ из sitemap (ED-8], метаданные из seoTitle/seoDescription (US-E1-04, SR-SEO-1], без N+1 (A-10b/A-10d]. |
| 2026-09-07 | AID   | Реализовано: `generateMetadata` в странице сценария; страница игры `games/[slug]` + `GameClient`; `tsc`/`lint` чисты. |