---
spec_id: SP-E10-01
title: "Спецификация реализации: главная страница сайта из агрегатов"
story_id: US-E10-01
status: drafted
updated: "2026-09-11"
---

# Спецификация реализации — US-E10-01 «Главная страница сайта: витрина, группы, карусель»

## 1. Scope

**В объёме:** `src/app/page.tsx` — серверный компонент: `getHomeFeed` +
`getSitemap` (2 чтения, A-10b). Витрина (`vitrine`) — карточки (title,
subtitle, imageRef) со ссылками на `/scenarios/{slug}`; группы смысла
(`groups`) — ссылки на `/scenarios` (деталок групп на сайте нет — решение
открытого вопроса стори); карусель (`carousel`) — слайды со ссылками на
`/games/{slug}` (slug из `sitemap.gameEntries`; gameId извлекается из
`imageRef` формата `games/{id}/…` — у `Slide` нет ссылки на игру; без
совпадения слайд без ссылки). Медиа — `SupabaseImage` (ED-14).

**Вне scope:** деталки групп; визуальный редизайн сайта (E10 — данные и
структура, стили в духе существующих страниц); аналитика.

## 2. Шаги

1. `src/lib/contract/links.ts` — хелперы: `gameIdFromImageRef(ref)`
   (парсинг `games/{id}/…`), `titleFromSlug(slug)` (fallback-заголовок).
2. `src/app/page.tsx` — рендер витрины/групп/карусели; состояния: db/feed
   null → текстовая заглушка (билд без секретов не падает).
3. Билд `NEXT_PUBLIC_ENV=dev npm run build` — контент в `out/index.html`.
4. Тесты `links.test.mjs` (node --test).

## 3. Файлы

`src/app/page.tsx`, `src/lib/contract/links.ts` (нов), `src/lib/contract/links.test.mjs` (нов).

## 4. Риски

| Риск | Митигация |
|---|---|
| Парсинг gameId из imageRef хрупкий | Единый хелпер + тесты; слайд без распознанного id — без ссылки |
| Билд без секретов | `getDb()` null → заглушка, как в деталках (US-E4-01) |

## 5. Verify

- AC-01: `out/index.html` содержит витрину/группы/карусель из dev-агрегатов.
- AC-02: 2 чтения Firestore на билд страницы (home_feed + sitemap).
- AC-03: контент в статическом HTML (output: export).
