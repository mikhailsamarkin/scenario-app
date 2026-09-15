---
spec_id: SP-E10-03
title: "Спецификация реализации: список игр /games и навигация"
story_id: US-E10-03
status: drafted
updated: "2026-09-11"
---

# Спецификация реализации — US-E10-03 «Страница списка игр»

## 1. Scope

**В объёме:** новая страница `src/app/games/page.tsx` — серверный компонент:
`getSitemap` + `getHomeFeed` (2 чтения). Список игр из
`sitemap.gameEntries`; caption/alt/imageRef карточек — из
`home_feed.carousel` (gameId из `imageRef` через `gameIdFromImageRef`);
без совпадения — fallback `titleFromSlug(slug)`. Ссылки — `/games/{slug}`.
Навигация `layout.tsx`: пункт «Игры» + восстановление абсолютных ссылок
(`/scenarios`, `/games`) вместо экспериментальных относительных из WIP
(относительные ссылки ломаются на вложенных маршрутах).

**Вне scope:** деталки игры (US-E4-01).

## 2. Шаги

1. `src/app/games/page.tsx` (нов).
2. `src/app/layout.tsx` — навигация «Сценарии», «Игры».
3. `src/app/games/[slug]/GameView.tsx` — ссылка назад `/scenarios`.
4. Билд и проверка `out/games/index.html`.

## 3. Файлы

`src/app/games/page.tsx` (нов), `src/app/layout.tsx`,
`src/app/games/[slug]/GameView.tsx`.

## 4. Риски

Игры без слайдов в карусели home показываются слагом — приемлемо;
follow-up при необходимости.

## 5. Verify

- AC-01: все slug игр из sitemap в `out/games/index.html`.
- AC-02: 2 чтения. AC-03: статический HTML; навигация на /games из шапки.
