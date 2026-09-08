---
spec_id: SP-E8-02
title: "Спецификация реализации: страница политики конфиденциальности на сайте"
story_id: US-E8-02
status: approved
updated: "2026-09-08"
---
# Спецификация реализации — US-E8-02 «Страница политики конфиденциальности на сайте»

## 1. Scope

**В объёме:**

* **Страница `/privacy`** на сайте (SSG Next.js) (**SR-PRIV-5**, **ED §2**).

* **URL стабилен** и совпадает с константой в МП (`https://scenario-games.ru/privacy`, **US-E6-04**).

* **Текст** — placeholder до утверждения (**US-E8-03**).

**Вне scope:**

* Текст политики (юридический) — **US-E8-03**.

* Вход из МП — **US-E6-04** (реализован).

## 2. Требования → шаги

| #  | Требование                                                        | Источник          | Шаги |
| -- | ----------------------------------------------------------------- | ----------------- | ---- |
| R1 | Страница `/privacy` возвращает 200 и содержит текст               | AC-01, SR-PRIV-5  | 1    |
| R2 | URL совпадает с константой в МП                                   | AC-02, US-E6-04   | 1    |

## 3. Архитектура данных

```mermaid
flowchart TD
  subgraph SITE["Next.js SSG"]
    PRIVACY[/privacy]
  end

  subgraph MP["МП / Flutter"]
    ABOUT[AboutScreen]
  end

  ABOUT -->|kPrivacyPolicyUrl| PRIVACY
```

**Ключевые решения:**

* **Страница `/privacy`**: статическая страница Next.js (`src/app/privacy/page.tsx`).

* **URL**: `https://scenario-games.ru/privacy` — совпадает с `kPrivacyPolicyUrl` в МП.

## 4. Шаги (в порядке зависимостей)

### Шаг 1. Страница /privacy

* `src/app/privacy/page.tsx`: статическая страница с текстом политики (placeholder).

* **Реализовано:** `src/app/privacy/page.tsx` — статическая страница; билд генерирует `/privacy`, GET → 200.

### Шаг 2. Тесты

| AC    | Слой  | Проверка                                             | Где                          |
| ----- | ----- | ---------------------------------------------------- | ---------------------------- |
| AC-01 | integration | GET /privacy → 200 и контент                        | билд/SSG                     |
| AC-02 | unit    | URL совпадает с kPrivacyPolicyUrl                   | контракт-тест                |

## 5. Файлы

* `docs/product/specs/e8-privacy-policy-page.md` — **настоящий документ** (SP-E8-02).

* `scenario-site/src/app/privacy/page.tsx` — страница политики (предлагается).

## 6. Риски

* **Текст не утверждён** — placeholder до US-E8-03.

## 7. Follow-up (вне scope)

* Текст политики — **US-E8-03**.

## 8. Доступы и блокеры

* **Блокер:** текст политики (**US-E8-03**).

* **A-40**: секреты — только env/Secret Manager, не в git.

## 9. Verify

Соответствие критериям приёмки **US-E8-02**:

* **AC-01 (SR-PRIV-5)** — GET /privacy → 200 и контент (билд).

* **AC-02** — URL совпадает с `kPrivacyPolicyUrl` (контракт-тест).

Критерий готовности: страница `/privacy` реализована; URL совпадает с МП.

## 10. История изменений

| Дата       | Автор | Изменение |
| ---------- | ----- | --------- |
| 2026-09-08 | AID   | Первая версия (drafted). Страница /privacy, placeholder-текст. |
| 2026-09-08 | AID   | Реализовано: `privacy/page.tsx`, URL совпадает с `kPrivacyPolicyUrl`. Текст — placeholder до **US-E8-03**. |