---
spec_id: SP-E5-03
title: "Спецификация реализации: веб-fallback — OG и сохранение UTM"
story_id: US-E5-03
status: approved
updated: "2026-09-08"
---
# Спецификация реализации — US-E5-03 «Веб-fallback: OG и сохранение UTM»

## 1. Scope

**В объёме:**

* **OG-теги** на странице сценария сайта из полей контента (**US-E1-04**, **AC-01**).

* **Сохранение UTM** в query-параметрах при редиректах (**A-25**, **AC-02**).

* **Тесты**: контракт/unit-тесты OG и UTM.

**Вне scope:**

* CTA установки МП — **US-E4-03**.

* Universal Links — **US-E5-02**.

* Аналитика конверсии по UTM — **use-cases** §6.2.

## 2. Требования → шаги

| #  | Требование                                                          | Источник          | Шаги |
| -- | ------------------------------------------------------------------- | ----------------- | ---- |
| R1 | OG-теги из полей контента на странице сценария                      | AC-01, FR-W-4, US-E1-04 | 2    |
| R2 | UTM сохраняются при редиректах                                      | AC-02, A-25       | 3    |

## 3. Архитектура данных

```mermaid
flowchart TD
  subgraph SITE["Next.js SSG"]
    PAGE[scenarios/[slug]/page.tsx]
    META[generateMetadata + openGraph]
  end

  subgraph DATA["ScenarioPublic"]
    SHARE[shareTitle/shareText/shareImageUrl]
  end

  PAGE --> META
  SHARE -->|og:title/og:description/og:image| META
```

**Ключевые решения:**

* **OG из полей контента** (**US-E1-04**): `openGraph.title` = `shareTitle ?? seoTitle ?? title`; `openGraph.description` = `shareText ?? seoDescription`; `openGraph.images` = `supabasePublicUrl(shareImageUrl)` (если есть).

* **UTM сохраняются** (**A-25**): редиректы не сбрасывают query-параметры (нет редиректов, теряющих query).

## 4. Шаги (в порядке зависимостей)

### Шаг 1. OG-теги в generateMetadata

* Добавить `openGraph` в `generateMetadata` страницы сценария.

* `og:title`, `og:description`, `og:image` из полей контента (US-E1-04).

* **Реализовано:** `scenarios/[id]/page.tsx` — `openGraph` из `shareTitle`/`shareText`/`shareImageUrl` (supabasePublicUrl).

### Шаг 2. Проверка UTM

* Убедиться, что редиректы сохраняют query-параметры (A-25).

* **Реализовано:** сайт не имеет редиректов, сбрасывающих query; URL с UTM сохраняет параметры (тест).

### Шаг 3. Тесты

| AC    | Слой  | Проверка                                             | Где                          |
| ----- | ----- | ---------------------------------------------------- | ---------------------------- |
| AC-01 | unit    | OG-теги из полей контента                            | контракт-тесты               |
| AC-02 | unit    | UTM сохраняются при редиректе                        | unit-тест                    |

* Контракт-тесты: наличие OG-полей; unit-тест сохранения UTM.

* **Реализовано:** `contract.test.mjs` — тест UTM (A-25).

## 5. Файлы

* `docs/product/specs/e5-web-fallback-og-utm.md` — **настоящий документ** (SP-E5-03).

* `scenario-site/src/app/scenarios/[id]/page.tsx` — OG-теги (реализовано).

* `scenario-site/src/lib/contract/types.ts` — `ScenarioPublic` (существует).

* `scenario-site/src/lib/contract/contract.test.mjs` — тест UTM (реализовано).

## 6. Риски

* **shareImageUrl не заполнен** — OG без изображения. Митиг: опционально.

* **UTM теряются при редиректе** — нарушение A-25. Митиг: проверить цепочку редиректов.

## 7. Follow-up (вне scope)

* CTA — **US-E4-03**; Universal Links — **US-E5-02**; аналитика — **use-cases** §6.2.

## 8. Доступы и блокеры

* **E4**, домен и SSL (**A-23**).

* **A-40**: секреты — только env/Secret Manager, не в git.

## 9. Verify

Соответствие критериям приёмки **US-E5-03**:

* **AC-01 (FR-W-4)** — страница сценария отдаёт OG из полей контента (unit-тест).

* **AC-02 (A-25)** — UTM сохраняются при редиректе (unit-тест).

Критерий готовности: OG-теги на странице сценария; UTM не теряются; unit-тесты AC-01..AC-02 зелёные.

## 10. История изменений

| Дата       | Автор | Изменение                                                                                                                          |
| ---------- | ----- | ---------------------------------------------------------------------------------------------------------------------------------- |
| 2026-09-07 | AID   | Первая версия (drafted]. OG-теги из полей контента (US-E1-04], сохранение UTM (A-25]. |
| 2026-09-07 | AID   | Реализовано: OG-теги в `scenarios/[id]/page.tsx`; тест UTM в `contract.test.mjs`. |