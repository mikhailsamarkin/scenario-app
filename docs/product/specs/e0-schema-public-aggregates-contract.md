---
spec_id: SP-E0-01
title: "Спецификация реализации: схема коллекций и публичных агрегатов (единый контракт МП и Next.js)"
story_id: US-E0-01
status: approved
updated: "2026-09-07"
---
# Спецификация реализации — US-E0-01 «Схема коллекций и публичных агрегатов для единого контракта МП и Next.js»

## 1. Scope

**В объёме:**

* Зафиксировать имена коллекций и документов **публичных агрегатов** (в т.ч. `*_public`, `home_feed`) для единого контракта чтения МП и сайта на Next.js — по **СТ §4, §5 (A-10, A-12)**.

* Описать **поля и связи** публичных агрегатов на уровне контракта — без выдуманных полей, строго по **СТ §4**.

* Задать **единый документ схемы** как точку согласования для Flutter (МП) и Next.js (SSG): имена, семантика, порядок, связи.

* Описать **Firestore Security Rules** (публичный read только к опубликованным/публичным путям; черновики недоступны клиентскому read — **A-38**) + эмулятор-тесты правил.

* Описать модель **версионирования контента** (`updatedAt` / `contentVersion`) для ISR и инвалидации кэша — **A-10e, A-44**.

* Задать **seed-фикстуры** (опубликованное + черновики) и **контрактные тесты** в духе тест-кейсов US-E0-01 (TC-01..TC-05).

**Вне scope:**

* Полная реализация Next.js SSG (эпик **E4**) — здесь только контракт данных, который SSG будет читать.

* Бизнес-логика импорта/публикации контента (эпик **E1**) — здесь только **форма данных** (`published` → публичные агрегаты), а не сам пайплайн.

* **Деплой правил в прод** и финальные Storage Rules — реальные правила Firestore деплоятся в **ADR-011** (отдельная задача); в этой стори — их **проектирование** и **эмулятор-тесты**.

* Слой BFF (Cloud Function + CDN) — по **A-11** не требуется для MVP.

* Storage Rules (Supabase) — отдельно по **A-39** (здесь только связка `imageRef` → публичный URL).

## 2. Требования → шаги

| #   | Требование                                                                             | Источник           | Шаги   |
| --- | -------------------------------------------------------------------------------------- | ------------------ | ------ |
| R1  | Один согласованный контракт данных для МП и Next.js                                    | AC-02, A-10b, A-12 | 1–2    |
| R2  | Зафиксированы имена коллекций/документов публичных агрегатов (`*_public`, `home_feed`) | стори, СТ §4, A-12 | 2–3    |
| R3  | Поля и связи агрегатов соответствуют СТ §4, без выдуманных полей                       | AC-02, A-10        | 3      |
| R4  | Черновики недоступны клиентскому read                                                  | AC-01, A-38        | 6      |
| R5  | Публичный read только к опубликованным путям; запись — service account                 | A-38               | 6      |
| R6  | `home_feed` (или эквивалент) достаточен для главного экрана МП                         | AC-03, A-12        | 2–3    |
| R7  | Версионирование контента для ISR/кэша                                                  | A-10e, A-44        | 3, 4   |
| R8  | Схема — единая точка согласования МП и SSG                                             | стори              | 1, 4–5 |
| R9  | Перелинковка сценарии ↔ игры без N+1                                                   | A-10d              | 3      |
| R10 | Контрактные тесты на соответствие схеме и правилам                                     | TC-01..TC-05       | 6–7    |

## 3. Архитектура данных

```mermaid
flowchart TD
  subgraph SOT["Источник правды (Firestore, закрыт для клиентского read)"]
    G[games]
    SC[scenarios]
    SG[semantic_groups]
    SSG[scenario_semantic_groups]
    SGG[scenario_games]
  end

  subgraph PUB["Публичные агрегаты (read-only для клиентов)"]
    HF[home_feed/main]
    SGP[semantic_groups_public/{id}]
    SP[scenario_public/{scenarioId}]
    GPP[game_public/{gameId}]
    SM[sitemap_public/main]
  end

  PUBLISH[Публикация/импорт\nservice account] -->|по published\nA-10, A-38| PUB
| --- | --- | --- |

  HF --> MP[МП / Flutter]
  SGP --> MP
  SP --> MP
  GPP --> MP
  SM --> SITE[Next.js SSG]
  SP --> SITE
  GPP --> SITE
```

**Ключевые решения:**

* **Источник правды закрыт.** `games`, `scenarios`, `semantic_groups`, `scenario_semantic_groups`, `scenario_games` — черновики и полные данные; клиентский read к ним **запрещён** (**A-38**). Публикация собирает из них денормализованные `*_public`-документы (**A-10**).

* **Один контракт.** МП и Next.js читают **только** публичные агрегаты; имена/поля/семантика зафиксированы в этом документе и в JSON Schema-артефакте (§4).

* **Достаточность главного экрана.** `home_feed` несёт карусель + витрину + ссылки на группы — МП строит главный экран без цепочки запросов к черновикам (**A-12**, **AC-03**).

* **Перелинковка без N+1.** `scenario_public` содержит упорядоченный список игр (со `slug`), `game_public` — список связанных сценариев (со `slug`); `sitemap_public` перечисляет все опубликованные `slug` для `generateStaticParams` (**A-10b, A-10d**).

* **Версионирование.** Каждый публичный документ несёт `updatedAt` и `contentVersion` (**A-10e, A-44**).

## 4. Документ схемы (контракт)

### 4.1. Источник правды (закрыт, поля — по СТ §4)

| Коллекция                  | СТ    | Ключевые поля                                                                                                                                                                                            | Клиентский read |
| -------------------------- | ----- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------- |
| `games`                    | §4.1  | `id`, `slug`, `title`, `seoTitle`, `seoDescription`, `playersHint`, `durationBucket`, `ageHint`, `rulesComplexity`, `carousel` (array<Slide>), `createdAt`, `updatedAt`                                  | нет             |
| `scenarios`                | §4.2  | `id`, `slug`, `title`, `subtitle`, `whyTheseGames`, `published`, `publishedAt`, `onHomeVitrine`, `vitrineOrder`, `shareTitle`, `shareText`, `shareImageUrl`, `utmCampaign`, `seoTitle`, `seoDescription` | нет             |
| `semantic_groups`          | §4.2a | `id`, `title`, `slug`, `listOrder`, `isPastArchive`                                                                                                                                                      | нет             |
| `scenario_semantic_groups` | §4.2b | `scenarioId`, `semanticGroupId`, `order` (пара уникальна)                                                                                                                                                | нет             |
| `scenario_games`           | §4.3  | `scenarioId`, `gameId`, `order`, `shortDescription`                                                                                                                                                      | нет             |

Примечания:

* `playersHint` / `ageHint` / `durationBucket` / `rulesComplexity` — закрытые enum по **CR-4.1**; в Firestore хранится **ключ**, подпись на русском — в UI (см. СТ §4.1).

* `Slide` = `{ imageRef, frameType (teaser|box|in_play|mechanic_closeup), caption, alt }`; минимум один слайд `teaser` (**CR-5**).
  \| --- | --- | --- | --- |

* Массив `semanticGroupIds` на `scenarios` как **каноническое** хранение не используется (**A-4c**); в публичных документах допускается как **производное** от `scenario_semantic_groups` при публикации.

### 4.2. Публичный агрегат `home_feed` (документ `home_feed/main`)

Агрегат главного экрана МП (**A-12**). Пересобирается при публикации любого сценария/игры.

| Поле             | Тип                  | Обяз. | Комментарий                                                                       |
| ---------------- | -------------------- | ----- | --------------------------------------------------------------------------------- |
| `contentVersion` | int                  | да    | Монотонно растёт при пересборке (**A-44**)                                        |
| `updatedAt`      | timestamp            | да    | Для ISR/webhook (**A-10e**)                                                       |
| `carousel`       | array\<Slide>        | да    | Избранные слайды по **CR-5**; клиент читает карусель из `home_feed` (A-12)        |
| `vitrine`        | array\<ScenarioCard> | да    | Упорядоченная витрина: только `onHomeVitrine: true`, сортировка по `vitrineOrder` |
| `groups`         | array\<GroupRef>     | да    | Ссылки на группы смысла в порядке `listOrder`                                     |

**`ScenarioCard`** (карточка витрины):
`{ scenarioId, slug, title, subtitle, imageRef, alt }`

**`GroupRef`** (ссылка на группу на главном экране):
`{ semanticGroupId, slug, title }`

Достаточность для главного экрана (**AC-03**): карточки содержат `scenarioId`/`slug`/`title`/`subtitle`/`imageRef`; переход на экран сценария — через `scenarioId`. Никаких обращений к черновикам.

### 4.3. Публичный агрегат группы `semantic_groups_public` (коллекция, документ `semantic_groups_public/{id}`)

Экран/блок группы смысла (в т.ч. «Сценарии прошлого» через `isPastArchive`).

| Поле             | Тип                  | Обяз. | Комментарий                                                                                             |
| ---------------- | -------------------- | ----- | ------------------------------------------------------------------------------------------------------- |
| `id`             | string               | да    | == источник `semantic_groups.id`                                                                        |
| `title`          | string               | да    | <br />                                                                                                  |
| `slug`           | string               | да    | URL группы на сайте                                                                                     |
| `listOrder`      | number               | нет   | Порядок блока на главном экране                                                                         |
| `isPastArchive`  | bool                 | да    | `true` для «Сценариев прошлого»                                                                         |
| `scenarios`      | array\<ScenarioCard> | да    | Упорядоченный список сценариев группы (порядок `scenario_semantic_groups.order`); только опубликованные |
| `contentVersion` | int                  | да    | <br />                                                                                                  |
| `updatedAt`      | timestamp            | да    | <br />                                                                                                  |

Связь «сценарий ↔ группа» берётся из `scenario_semantic_groups` и **денормализуется** сюда при публикации (**A-10**); массив `semanticGroupIds` на сценарии — производное (**A-4c**).

### 4.4. Публичный агрегат сценария `scenario_public` (коллекция, документ `scenario_public/{scenarioId}`)

Экран сценария (МП) и страница сценария (сайт, SEO).

| Поле                                       | Тип                     | Обяз.     | Комментарий                                                                                    |
| ------------------------------------------ | ----------------------- | --------- | ---------------------------------------------------------------------------------------------- |
| `id`                                       | string                  | да        | == источник `scenarios.id` (A-13)                                                              |
| `slug`                                     | string                  | да        | URL/universal link                                                                             |
| `title`                                    | string                  | да        | <br />                                                                                         |
| `subtitle`                                 | string                  | нет       | Тизер в списках                                                                                |
| `whyTheseGames`                            | string (plain text)     | да        | «Почему эти игры» (**CR-4**), без Markdown/HTML (**A-4a**)                                     |
| `seoTitle`                                 | string                  | да/желат. | Мета-тег страницы; fallback из `title`/`subtitle` по правилу (**A-10c**)                       |
| `seoDescription`                           | string                  | да/желат. | Мета-description                                                                               |
| `shareTitle`, `shareText`, `shareImageUrl` | string                  | нет       | Шаринг/OG (**FR-M-7, A-10c**)                                                                  |
| `publishedAt`                              | timestamp               | нет       | Триггер «новый сценарий»                                                                       |
| `semanticGroupIds`                         | array\<string>          | нет       | Производное от `scenario_semantic_groups` (A-4c)                                               |
| `games`                                    | array\<ScenarioGameRef> | да        | **Упорядоченный** список игр по `scenario_games.order`; со `slug` для перелинковки (**A-10d**) |
| `contentVersion`                           | int                     | да        | <br />                                                                                         |
| `updatedAt`                                | timestamp               | да        | <br />                                                                                         |

**`ScenarioGameRef`** (игра в контексте сценария):
`{ gameId, slug, title, shortDescription, imageRef, alt, playersHint, durationBucket, ageHint, rulesComplexity }`

`shortDescription` берётся из связи `scenario_games` (**§4.3, CR-4**) — описание игры **в контексте сценария**; `playersHint`/`durationBucket`/`ageHint`/`rulesComplexity` — enum-ключи для чипов на экране.

### 4.5. Публичный агрегат игры `game_public` (коллекция, документ `game_public/{gameId}`)

Экран игры (МП) и страница игры (сайт, SEO).

| Поле                         | Тип                     | Обяз.     | Комментарий                                                                                            |
| ---------------------------- | ----------------------- | --------- | ------------------------------------------------------------------------------------------------------ |
| `id`                         | string                  | да        | == источник `games.id`                                                                                 |
| `slug`                       | string                  | да        | URL                                                                                                    |
| `title`                      | string                  | да        | <br />                                                                                                 |
| `seoTitle`, `seoDescription` | string                  | да/желат. | SEO                                                                                                    |
| `playersHint`                | enum                    | да        | Закрытый список (CR-4.1)                                                                               |
| `durationBucket`             | enum                    | да        | `warmup\|short\|evening\|long\|main_event`                                                             |
| `ageHint`                    | enum                    | да        | Закрытый список (CR-4.1)                                                                               |
| `rulesComplexity`            | enum                    | да        | `easy\|normal\|heavy`                                                                                  |
| `carousel`                   | array\<Slide>           | да        | CR-5                                                                                                   |
| `scenarios`                  | array\<GameScenarioRef> | да        | Связанные сценарии со `slug` для перелинковки (**A-10d**); каждый несёт `shortDescription` в контексте |
| `contentVersion`             | int                     | да        | <br />                                                                                                 |
| `updatedAt`                  | timestamp               | да        | <br />                                                                                                 |

**`GameScenarioRef`** (сценарий, где игра участвует):
`{ scenarioId, slug, title, shortDescription }`

Для **A-12** **`game_detail`** (`игра + shortDescription для текущего scenarioId`): клиент открывает `game_public/{id}`, находит в `scenarios` запись с нужным `scenarioId` и берёт её `shortDescription`; `scenarioId` приходит из deep link / push (**A-13**).

### 4.6. Публичный агрегат `sitemap_public` (документ `sitemap_public/main`)

Служебный индекс опубликованных `slug` для SSG — чтобы `generateStaticParams` и sitemap строились без N+1 по коллекциям (**A-10b, A-10d**).

| Поле             | Тип            | Обяз. | Комментарий                         |
| ---------------- | -------------- | ----- | ----------------------------------- |
| `scenarioSlugs`  | array\<string> | да    | Все опубликованные `slug` сценариев |
| `gameSlugs`      | array\<string> | да    | Все опубликованные `slug` игр       |
| `contentVersion` | int            | да    | <br />                              |
| `updatedAt`      | timestamp      | да    | <br />                              |

### 4.7. Соглашения по enum и изображениям

* **enum-ключи** хранятся в Firestore как ключи (`players_1`, `age_kids`, `warmup`, `easy` …), подпись на русском — в UI (**СТ §4.1**, **ED-2**).

* **`imageRef`** **/** **`alt`** — ссылка на объект в Supabase Storage и `alt`-текст для SEO/доступности (**CR-5**, **A-10c**). Публичный URL формируется по правилу из **SP-E0-02 / ED-14** (`supabasePublicUrl(path)`), разрешённые пути — `games/{id}/**` (**A-39**).

* **`contentVersion`** — целочисленный, монотонный, растёт при каждой пересборке публичного агрегата; используется для ISR `revalidate` и условной инвалидации кэша МП (**A-10e, A-44**).

* Публичные документы **не содержат** служебных/внутренних полей черновика (напр. `onHomeVitrine`, `vitrineOrder` — остаются в источнике правды и влияют на сборку `home_feed` только при публикации).

## 5. Файлы

* `docs/product/specs/e0-schema-public-aggregates-contract.md` — **настоящий документ** (SP-E0-01).

* `docs/product/schemas/content-contract.schema.json` (предлагается) — JSON Schema публичных агрегатов (4.2–4.6) для контрактных тестов МП/SSG (**TC-03, TC-04**).

* `scenario/lib/…` (предлагается, E0-реализация) — Dart-модели/типы публичных агрегатов (`HomeFeed`, `ScenarioPublic`, `GamePublic`, `GroupPublic`, `SitemapPublic`).

* `scenario-site/src/lib/…` (предлагается) — TS-типы публичных агрегатов + чтение из Firestore.

* `scenario-site/firestore.rules` — **проектирование** правил публичного read (деплой — ADR-011).

* `scenario-site/firestore.indexes.json` — индексы под запросы публичных агрегатов (по ADR-010).

* `scenario/test/…`, seed-фикстуры — эмулятор-тесты правил и контрактные тесты (TC-01..TC-05).

## 6. Риски

* **Именование агрегатов** (`*_public`, `home_feed`) не финализировано в ADR-010/ADR-011 — расхождение имён между документацией и кодом. Митиг: этот документ — единая точка согласования; правки схемы фиксируются в ADR.

* **Недокументированные поля** в данных, прочитанных клиентами (**TC-04**). Митиг: JSON Schema + allowlist-проверка в CI.

* **Деплой правил в прод** отложен до ADR-011 — до тех пор Firestore закрыт целиком (`allow read, write: if false`), сайт/МП не читают данные в проде. Митиг: в этой стори правила проектируются и тестируются в эмуляторе.

* **N+1 на сайте** при нарушении контракта перелинковки (**A-10d**). Митиг: `scenario_public`/`game_public`/`sitemap_public` несут готовые списки `slug`.

* **Расхождение enum** между источником, правилами и UI. Митиг: enum-allowlist в Firestore Rules + общие Dart/TS типы (**СТ §4.1**).

## 7. Follow-up (вне scope)

* Деплой реальных Firestore Rules и Storage Rules — **ADR-011**.

* Индексы Firestore под запросы агрегатов — **ADR-010**.

* Пайплайн импорта/публикации, собирающий `*_public` — эпик **E1**.

* Полная реализация SSG сайта — эпик **E4**.

## 8. Доступы и блокеры

* Согласование с **СТ** по именованию агрегатов и правилу миграции схемы — **ADR-010, ADR-011**.

* Доступ к Firebase-проектам (dev `scenario-ba26a`, prod `scenario-prod-491c`) для тестирования правил/эмулятора.

* **A-40:** секреты/ключи — вне репозитория.

## 9. Verify

Соответствие критериям приёмки **US-E0-01**:

* **AC-01 (A-38)** — TC-01: read черновика через публичный путь → permission denied/документ отсутствует; TC-02: опубликованный читается. Проверка в эмуляторе Firestore + unit-тесты правил.

* **AC-02 (A-10, A-12)** — TC-03/TC-04: имена коллекций и полей агрегатов совпадают с этим документом и **СТ §4**; нет недокументированных обязательных полей (JSON Schema/snapshot).

* **AC-03** — TC-05: структура `home_feed` достаточна для построения главного экрана МП без обращений к черновикам.

Критерий готовности: контрактные тесты (TC-01..TC-05) зелёные в эмуляторе; документ схемы согласован; JSON Schema выложена как артефакт.

## 10. История изменений

| Дата       | Автор | Изменение                                                                                        |
| ---------- | ----- | ------------------------------------------------------------------------------------------------ |
| 2026-09-03 | AID   | Первая версия (drafted). Схема публичных агрегатов по СТ §4/§5, A-38; контракт для МП и Next.js. |

