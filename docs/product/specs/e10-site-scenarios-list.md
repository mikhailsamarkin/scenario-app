---
spec_id: SP-E10-02
title: "Спецификация реализации: список сценариев /scenarios"
story_id: US-E10-02
status: drafted
updated: "2026-09-11"
---

# Спецификация реализации — US-E10-02 «Страница списка сценариев»

## 1. Scope

**В объёме:** `src/app/scenarios/page.tsx` (сейчас заглушка) — серверный
компонент: `getSitemap` + `getHomeFeed` (2 чтения). Полный список
опубликованных сценариев из `sitemap.scenarioEntries`; заголовок/subtitle/
imageRef — из `home_feed.vitrine` (по scenarioId); для сценария вне витрины
(снят с витрины, E7-02) — fallback `titleFromSlug(slug)` без картинки
(решение открытого вопроса стори: без N+1 чтений `scenario_public`).
Ссылки — `/scenarios/{slug}`.

**Вне scope:** группы смысла (US-E10-01); деталки (US-E4-01).

## 2. Шаги

1. `src/app/scenarios/page.tsx` — список карточек; заглушка при db/feed null.
2. Билд и проверка `out/scenarios/index.html`.

## 3. Файлы

`src/app/scenarios/page.tsx`, переиспользуются `links.ts`, `SupabaseImage`.

## 4. Риски

Сценарии вне витрины показываются слагом-заголовком — приемлемо для
архива; follow-up: подгрузка групп смысла (N чтений по числу групп)
если потребуется красивый список архива.

## 5. Verify

- AC-01: все slug из sitemap присутствуют в `out/scenarios/index.html`.
- AC-02: 2 чтения. AC-03: статический HTML.
