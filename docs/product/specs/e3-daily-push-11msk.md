---
spec_id: SP-E3-03
title: "Спецификация реализации: не больше одного push в сутки в 11:00 МСК"
story_id: US-E3-03
status: approved
updated: "2026-09-07"
---
# Спецификация реализации — US-E3-03 «Не больше одного push в сутки в 11:00 МСК»

## 1. Scope

**В объёме:**

* **Ежедневный push в 11:00 МСК** — не более одного сообщения на topic за календарные сутки (**A-7a**, **AC-01**).

* **Последний опубликованный сценарий** из очереди `pending_notifications/daily` (**A-32**, **AC-02**).

* **Topic `new_scenarios`** (**SR-PUSH-1**) и **payload `scenarioId`** для deep link (**US-E3-04**).

* **Текст из данных/конфига** (**ED-11**, **AC-03**).

* **Тесты**: unit-тесты логики выбора и payload (AC-01..AC-03).

**Вне scope:**

* Подписка клиента — **US-E3-02** (реализована).

* Deep link — **US-E3-04** (реализован).

* Universal Links — **E5**.

## 2. Требования → шаги

| #  | Требование                                                          | Источник          | Шаги |
| -- | ------------------------------------------------------------------- | ----------------- | ---- |
| R1 | Один push в сутки в 11:00 МСК                                       | AC-01, A-7a       | 2    |
| R2 | Последний сценарий из очереди                                       | AC-02, A-32       | 2    |
| R3 | Topic `new_scenarios`, payload `scenarioId`                         | SR-PUSH-1, US-E3-04 | 3    |
| R4 | Текст из данных/конфига                                             | AC-03, ED-11      | 3    |

## 3. Архитектура данных

```mermaid
flowchart TD
  subgraph FS["Firestore"]
    QUEUE[pending_notifications/daily\nlastScenarioId]
    SP[scenario_public/{id}]
  end

  subgraph CRON["GitHub Actions cron 11:00 МСК"]
    PUSH[daily-push.mjs]
  end

  subgraph FCM["FCM"]
    TOPIC[new_scenarios]
  end

  QUEUE -->|lastScenarioId| PUSH
  SP -->|title/текст| PUSH
  PUSH -->|topic new_scenarios, data.scenarioId| TOPIC
```

**Ключевые решения:**

* **Источник — очередь** (**A-32**): `pending_notifications/daily.lastScenarioId` — последний опубликованный сценарий (перезаписывается при публикации, A-7a).

* **Topic `new_scenarios`** (**SR-PUSH-1**): рассылка на topic новых сценариев (согласовано с клиентом US-E3-02).

* **Payload `scenarioId`** (**US-E3-04**): `data.scenarioId` для deep link на сценарий.

* **Текст из данных** (**ED-11**): заголовок/тело из `scenario_public` (title) или конфига.

## 4. Шаги (в порядке зависимостей)

### Шаг 1. Чтение очереди

* Читать `pending_notifications/daily` → `lastScenarioId`.

* Если записи нет — пропуск (нет новинок).

* **Реализовано:** `daily-push.mjs` читает очередь; `pickLastScenarioId` в `daily-push-logic.mjs`.

### Шаг 2. Выбор сценария (AC-02)

* По `lastScenarioId` читать `scenario_public/{id}` для title/текста.

* Это последний опубликованный сценарий (A-32).

* **Реализовано:** `daily-push.mjs` читает `scenario_public/{id}`; `buildPushMessage` берёт текст из данных.

### Шаг 3. Отправка (AC-01, AC-03, SR-PUSH-1)

* `topic: 'new_scenarios'` (SR-PUSH-1).

* `notification.title`/`body` из данных сценария (ED-11).

* `data.scenarioId` для deep link (US-E3-04).

* Один вызов в сутки (cron 11:00 МСК, A-7a).

* **Реализовано:** `buildPushMessage` (topic `new_scenarios`, data `scenarioId`); cron в `daily-push.yml`.

### Шаг 4. Тесты

| AC    | Слой  | Проверка                                             | Где                          |
| ----- | ----- | ---------------------------------------------------- | ---------------------------- |
| AC-01 | unit    | Один push в сутки (cron)                             | конфиг cron                  |
| AC-02 | unit    | Последний сценарий из очереди                        | unit-тест логики             |
| AC-03 | unit    | Текст из данных; payload scenarioId                  | unit-тест payload            |

* Unit-тесты логики выбора и формирования payload.

* **Реализовано:** `scenario-site/scripts/daily-push-logic.test.mjs` — 3 теста (AC-02, AC-03).

## 5. Файлы

* `docs/product/specs/e3-daily-push-11msk.md` — **настоящий документ** (SP-E3-03).

* `scenario-site/scripts/daily-push.mjs` — ежедневный push (реализовано, переработан).

* `scenario-site/scripts/daily-push-logic.mjs` — чистая логика (реализовано).

* `scenario-site/scripts/daily-push-logic.test.mjs` — unit-тесты (реализовано).

* `scenario-site/.github/workflows/daily-push.yml` — cron 11:00 МСК (существует).

## 6. Риски

* **Очередь пуста** — нет новинок, пропуск. Митиг: обработка отсутствия записи.

* **Сценарий не найден** — корректная ошибка. Митиг: проверка существования.

* **Topic не совпадает с клиентом** — клиент подписан на `new_scenarios`. Митиг: согласовано (SR-PUSH-1).

## 7. Follow-up (вне scope)

* Алерты по ошибкам Scheduler — **use-cases** §6.2.

## 8. Доступы и блокеры

* **US-E1-05** очередь (реализована).

* FCM, cron, таймзона МСК.

* **A-40**: секреты — только env/Secret Manager, не в git.

## 9. Verify

Соответствие критериям приёмки **US-E3-03**:

* **AC-01 (A-7a)** — не более одного сообщения на topic за сутки (cron 11:00 МСК).

* **AC-02 (A-32)** — при нескольких новинках — последний сценарий из очереди (unit-тест).

* **AC-03 (ED-11)** — текст из данных/конфига, payload `scenarioId` (unit-тест).

Критерий готовности: `daily-push.mjs` читает очередь, берёт последний сценарий, шлёт на `new_scenarios` с `scenarioId`; unit-тесты AC-01..AC-03 зелёные.

## 10. История изменений

| Дата       | Автор | Изменение                                                                                                                          |
| ---------- | ----- | ---------------------------------------------------------------------------------------------------------------------------------- |
| 2026-09-07 | AID   | Первая версия (drafted]. Ежедневный push: очередь → последний сценарий (A-32], topic new_scenarios (SR-PUSH-1], payload scenarioId (US-E3-04], текст из данных (ED-11]. |
| 2026-09-07 | AID   | Реализовано: `daily-push.mjs` (очередь → сценарий → topic new_scenarios], `daily-push-logic.mjs` + тесты; workflow без FCM_TOPIC. |