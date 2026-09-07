---
spec_id: SP-E5-02
title: "Спецификация реализации: Universal Links / App Links — открытие сценария в приложении"
story_id: US-E5-02
status: drafted
updated: "2026-09-07"
---
# Спецификация реализации — US-E5-02 «Universal Links / App Links»

## 1. Scope

**В объёме:**

* **Обработка HTTPS-ссылок** `https://scenario-games.ru/scenario/{slug}` в МП (**A-23**, **A-24**, **AC-01**).

* **Открытие сценария** по ссылке: извлечь `slug` → найти `id` (через sitemap) → открыть экран сценария.

* **Холодный старт** и фоновое открытие по ссылке (**AC-01**).

* **Тесты**: unit/widget-тесты обработки URL (AC-01, AC-02).

**Вне scope:**

* Системный share — **US-E5-01** (реализован).

* Веб-fallback OG/UTM — **US-E5-03** (реализован).

* Аналитика воронки — **US-E5-04**.

## 2. Требования → шаги

| #  | Требование                                                          | Источник          | Шаги |
| -- | ------------------------------------------------------------------- | ----------------- | ---- |
| R1 | HTTPS-ссылка на сценарий открывает приложение со сценарием          | AC-01, A-24, FR-M-7 | 2    |
| R2 | Извлечение slug → id через sitemap                                  | A-23, A-13        | 2    |
| R3 | AASA/assetlinks валидны                                             | AC-02, A-24       | 1    |

## 3. Архитектура данных

```mermaid
flowchart TD
  subgraph MP["МП / Flutter"]
    LINKS[app_links.uriLinkStream]
    PARSE[parse: scenario/{slug}]
    FIND[slug → id (sitemap)]
    NAV[ScenarioScreen]
  end

  subgraph URL["https://scenario-games.ru"]
    SLUG[scenario/{slug}]
  end

  URL --> LINKS
  LINKS --> PARSE
  PARSE --> FIND
  FIND --> NAV
```

**Ключевые решения:**

* **app_links** (**A-24**): пакет `app_links` для перехвата HTTPS-ссылок (Universal Links / App Links).

* **slug → id** (**A-23**, **A-13**): URL `scenario/{slug}`; id пути — из `sitemap_public.scenarioEntries` (маппинг slug→id).

* **Холодный старт**: при запуске обработать initial link; далее — подписка на `uriLinkStream`.

## 4. Шаги (в порядке зависимостей)

### Шаг 1. Конфигурация UL (iOS/Android)

* iOS: `apple-app-site-association` (AASA) для домена `scenario-games.ru`; xроный entitlement.

* Android: `assetlinks.json` + intent-filter на HTTPS.

* Конфигурация публикуется на домене (в `scenario-site`).

* **Примечание:** конфигурация UL для iOS/Android требует доступа к DNS/стору и выкладывается на домене; здесь реализована клиентская обработка ссылок.

### Шаг 2. Обработка ссылок в МП

* Пакет `app_links`: подписка на `uriLinkStream` + initial link.

* Парсер: из URL `https://scenario-games.ru/scenario/{slug}` извлечь slug.

* slug → id через `sitemap_public.scenarioEntries`; открыть сценарий.

* **Реализовано:** `scenario/lib/features/link/universal_link_service.dart` — `UniversalLinkService` (parseScenarioSlug, resolveScenarioId, getInitialScenarioId, onScenarioOpened) + абстракция `LinkSource`; интеграция в `ScenarioApp`.

### Шаг 3. Тесты

| AC    | Слой  | Проверка                                             | Где                          |
| ----- | ----- | ---------------------------------------------------- | ---------------------------- |
| AC-01 | unit    | URL → slug → id → открытие сценария                  | unit-тест сервиса            |
| AC-02 | unit    | AASA/assetlinks валидны                             | проверка конфига             |

* Unit-тест парсера и маппинга slug→id.

* **Реализовано:** `scenario/test/universal_link_service_test.dart` — 4 теста (AC-01).

## 5. Файлы

* `docs/product/specs/e5-universal-links-app.md` — **настоящий документ** (SP-E5-02).

* `scenario/pubspec.yaml` — зависимость `app_links` (реализовано).

* `scenario/lib/features/link/universal_link_service.dart` — сервис обработки ссылок (реализовано).

* `scenario/lib/app.dart` — интеграция в `ScenarioApp` (реализовано).

* `scenario/test/universal_link_service_test.dart` — unit-тесты сервиса (реализовано).

## 6. Риски

* **Домен/SSL** — требуется валидный домен и SSL (A-23). Митиг: согласовать с E5/site.

* **Bundle id / package name** — должны совпадать с настройками UL. Митиг: проверить конфигурацию.

* **slug → id** — нужен маппинг из sitemap. Митиг: `scenarioEntries`.

## 7. Follow-up (вне scope)

* Аналитика воронки — **US-E5-04**.

## 8. Доступы и блокеры

* Домен `scenario-games.ru` и SSL.

* Bundle id / package name.

* **A-40**: секреты — только env/Secret Manager, не в git.

## 9. Verify

Соответствие критериям приёмки **US-E5-02**:

* **AC-01 (A-24)** — HTTPS-ссылка на сценарий открывает приложение с `scenarioId` (unit-тест).

* **AC-02 (A-23)** — AASA/assetlinks валидны (тест конфигурации).

Критериий готовности: `app_links` обрабатывает ссылку, slug → id → открытие сценария; unit-тесты AC-01..AC-02 зелёные.

## 10. История изменений

| Дата       | Автор | Изменение                                                                                                                          |
| ---------- | ----- | ---------------------------------------------------------------------------------------------------------------------------------- |
| 2026-09-07 | AID   | Первая версия (drafted]. Universal Links: app_links, slug → id (sitemap], настройка AASA/assetlinks. |
| 2026-09-07 | AID   | Реализовано: `universal_link_service.dart` (сервис + абстракция], интеграция в `ScenarioApp`; unit-тесты AC-01. |