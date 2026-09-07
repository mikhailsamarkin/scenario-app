---
spec_id: SP-E1-04
title: "Спецификация реализации: поля шаринга и SEO для сценария и игры"
story_id: US-E1-04
status: approved
updated: "2026-09-07"
---
# Спецификация реализации — US-E1-04 «Поля шаринга и SEO для сценария и игры»

## 1. Scope

**В объёме:**

* **Поля SEO/шаринга в контракте** (`scenario_public`, `game_public`) по **СТ §4.4 (A-10c)** и **FR-M-7**: `title`, `description`, OG-изображение; для сценария — дополнительно поля системного шаринга (`shareTitle`, `shareText`, `shareImageUrl`). Поля уже присутствуют в JSON Schema и Dart-моделях как опциональные; сторя фиксирует их **требуемость** и правила заполнения/валидации.

* **Импорт из репозитория** (`data/content/`) через скрипты в `tools/` (**ED-4**) — канал эксперта: источник контента заполняется полями SEO/шаринга; пайплайн проверяет их и переносит в исходные (`games`, `scenarios`) и публичные (`game_public`, `scenario_public`) документы.

* **Валидация полей** перед записью: plain text (**A-4a**), лимиты длин `title`/`description`, допустимая форма OG-изображения, обязательность SEO-полей для игры (**ED-9** — страница игры без «чужого» fallback).

* **Уникальность slug до публикации** (**ED-8**, AC-02): проверка уже реализована в `tools/import-game.mjs` / `tools/import-scenario.mjs`; здесь — фиксация поведения и тестовое покрытие.

* **Правило OG-изображения**: картинка хранится как **путь в Storage / публичный URL** и резолвится в абсолютный URL через `supabasePublicUrl(path)` (**A-39/§4.4**) в момент чтения (по примечанию сторин: «OG-картинки — пути в Storage / публичные URL по правилам проекта»).

* **Тесты**: TC-01…TC-04 из `docs/product/test-cases/e1-expert-sharing-seo-fields.md` (чтение полей, уникальность/конфликт slug, отсутствие «чужого» описания у игры).

**Вне scope:**

* UI системного share в МП — эпик **E5** (**US-E5-01**).

* Полная реализация Universal Links и SSG-сайта (**A-23–A-25, FR-W-2**) — эпики **E4/E5**; здесь только контракт и данные.

* Группы смысла и «Сценарии прошлого» (эпик **E7**).

* UTM-метки шаринга (`utmCampaign`) — **US-E5-01/US-E5-03** (приготовление предусмотрено в `content-intake.xlsx`; в этой стори не пишется).

* Деплой Firestore/Storage Rules в прод — **ADR-011** (проектирование правил здесь не меняется).

## 2. Требования → шаги

| #  | Требование                                                     | Источник                          | Шаги        |
| -- | -------------------------------------------------------------- | --------------------------------- | ----------- |
| R1 | Схема содержит title/description/OG для сценария и игры        | AC-01, §4.4 (A-10c), FR-M-7       | 1, 2        |
| R2 | Поля читаются из данных без хардкода в клиентах                | AC-01, FR-M-7, FR-W-2             | 1, 4        |
| R3 | Соблюдается ED-9: SEO-поля страницы игры обязательны, без fallback | AC-03, ED-9                     | 1, 3        |
| R4 | Slug уникален и проверяется до публикации                     | AC-02, ED-8                       | 3, 4        |
| R5 | OG-изображение — путь/URL по правилам проекта (A-39)          | A-10c, примечание сторин         | 1, 4        |
| R6 | Валидация и тесты на поля SEO/шаринга                         | TC-01…TC-04                       | 3, 6        |

## 3. Архитектура данных

```mermaid
flowchart TD
  subgraph SRC["Репозиторий (data/content)"]
    GJSON[games/*.json
+ seoTitle, seoDescription]
    SCJSON[scenarios/*.json
+ seoTitle, seoDescription,
+ shareTitle, shareText, shareImageUrl]
  end

  IMP[Скрипты импорта tools/
валидация + запись] -->|валидация A-4a, ED-8, ED-9| GJSON
  IMP -->|валидация A-4a, ED-8| SCJSON
  IMP -.->|upload изображений| SS[(Supabase Storage,
путь -> публичный URL A-39)]
  IMP -->|запись service account| FS[(Firestore)]

  subgraph FS["Firestore"]
    G[games - ист правды, закрыт]
    SC[scenarios - ист правды, закрыт]
    GPP[game_public/{gameId}
+ seoTitle, seoDescription (обяз.)]
    SP[scenario_public/{scenarioId}
+ seoTitle, seoDescription, share*]
  end

  G --> GPP
  SC --> SP
  GPP -->|read A-38| MP[МП / Flutter: share, OG]
  SP -->|read A-38| MP
  GPP -->|read A-10c| SSG[Next.js SSG: og:title/description/image (E4)]
  SP -->|read A-10c| SSG
```

**Ключевые решения:**

* **Поля в контракте уже есть** (заложено в **US-E0-01/US-E1-01**): `scenario_public.seoTitle/seoDescription/shareTitle/shareText/shareImageUrl` и `game_public.seoTitle/seoDescription`. Эта сторя уточняет обязательность и валидацию, **не меняя имена/структуру** — минимизирует риск рассинхрона МП/SSG.

* **Назначение полей**: `seoTitle`/`seoDescription` — метаданные **SEO-страниц** (**FR-W-2**); `shareTitle`/`shareText`/`shareImageUrl` — **системный share сценария** (**FR-M-7**, объект шаринга — только сценарий). Для игры объект шаринга отсутствует — только SEO-поля.

* **OG-изображение = путь/URL** (**ED-14, A-39**): `shareImageUrl` хранится как путь внутри Storage (по аналогии с `imageRef` слайдов) или абсолютный URL; при генерации `og:image` и системного шаринга резолвится через `supabasePublicUrl(path)`.

* **ED-9 — источник текста**: SEO-поля `game_public` заполняются **только из `games/{gameId}`**, никогда из `shortDescription` любого сценария; `scenario_public` также не подставляет текст из другого сценария. Публикация игры требует наличия своих `seoTitle`/`seoDescription` (обязательные) — иначе импорт отклоняется. Это и есть гарантия «без fallback».

* **Версионирование** (**A-10e, A-44**): изменение SEO-полей при повторной публикации инкрементирует `contentVersion`/`updatedAt` в `game_public`/`scenario_public` — основа инвалидации кэша (FR-M-3). Уже реализовано в скриптах.

## 4. Шаги (в порядке зависимостей)

### Шаг 1. Зафиксировать схему SEO/шаринга в контракте

Артефакты: `docs/product/schemas/content-contract.schema.json` (SP-E0-01) и Dart-модели `scenario/lib/data/contract/models.dart`. Имена полей не меняются; уточняется required-настройка.

**Сценарий** (`scenario_public`): 
* `seoTitle` — **обязателен** (по `content-intake.xlsx` — «да»); 
* `seoDescription` — желательно; 
* `shareTitle`/`shareText`/`shareImageUrl` — желательно (шаринг сценария не блокер публикации). 
* `canonical` на этом этапе не вводим (генерация базового URL — на стороне SSG в E4 по `slug`, см. A-23).

**Игра** (`game_public`): `seoTitle` и `seoDescription` — **обязательны** (**ED-9**). Это единственное изменение обязательности против текущей схемы.

Обновления:
* `content-contract.schema.json`: в `scenarioPublic` добавить `seoTitle` в `required`; в `gamePublic` добавить `seoTitle`, `seoDescription` в `required`. `shareTitle`/`shareText`/`shareImageUrl` остаются optional.
* Dart-модель: `GamePublic.seoTitle`/`seoDescription` — перевести на `required`; `ScenarioPublic.seoTitle` — `required`. Парсинг уже строгий (round-trip) — см. Шаг 6.

**Обратная совместимость**: старые опубликованные `game_public` без обязательных полей должны быть **отнаследованы/переимпортированы** (Шаг 4, фоновый backfill) до активации strict-парсинга в клиенте, либо клиент временно терпит `null` до E4. Зафиксировано в §6-риск.

### Шаг 2. Заполнить фикстуры контента

В файлы `data/content/games/*.json` и `data/content/scenarios/*.json` добавить поля по спеце Excel (`tools/make_content_excel.py`):

* `data/content/games/{game}.json`: `seoTitle` (обяз., ≤ ~60 симв.), `seoDescription` (желат., ≤ ~160 симв.).
* `data/content/scenarios/{scenario}.json`: `seoTitle` (обяз.), `seoDescription` (желат.), `shareTitle`/`shareText` (желат., plain text), `shareImageUrl` (желат., путь Storage/URL).

Актуальный набор: `games/codenames.json`, `games/munchkin.json`; `scenarios/semya.json`, `scenarios/vecherinka.json`. Для `shareImageUrl` — путь (например `images/share.jpg` или Storage-путь), правило — в Шаге 4.

Для тестов — негативные фикстуры в `data/content/{games,scenarios}/invalid/`: игра без `seoTitle`/`seoDescription`; сценарий без `seoTitle`; поле с Markdown/не-путь/не-URL.

### Шаг 3. Валидаторы

Реализация в `tools/validate-game.mjs` и `tools/validate-scenario.mjs` (Node, переиспользуют общие утилиты):

**`validate-game.mjs`**:
* Добавить `seoTitle`, `seoDescription` в требуемые поля (**ED-9**).
* `seoTitle`/`seoDescription` — plain text (**A-4a**); `seoTitle.length <= ~60`, `seoDescription.length <= ~160` (по Excel).

**`validate-scenario.mjs`**:
* `seoTitle` — обязательное поле (≤ ~60), plain text.
* `seoDescription`, `shareTitle`, `shareText` — если заданы: plain text; SEO-поля с лимитом длины.
* `shareImageUrl` — если задан: валидный путь Storage (bucket) или публичный URL; иначе ошибка.

Общее: успех — `{ok:true}`; ошибки — явные сообщения; при ошибке запись не выполняется.

### Шаг 4. Скрипты импорта

`tools/import-games.mjs` и `tools/import-scenario.mjs` уже переносят SEO/шаринг-поля в `games`/`scenarios` и в публичные агрегаты. Уточнения на этой стори:

* **`import-games.mjs`**: после валидации с required `seoTitle`/`seoDescription` записать их в `games/{id}` и `game_public/{gameId}` (уже выполняется). В `game_public` эти поля копируются **только из `games`**, никогда из сценария (**ED-9**). У игры `shareImageUrl` не добавляется (объект шаринга — сценарий).
* **`import-scenario.mjs`**: `scenario_public` переносит `seoTitle`/`seoDescription`/`shareTitle`/`shareText`/`shareImageUrl` (уже выполняется). Если `shareImageUrl` — локальный файл, загрузить в Storage по правилу слайдов и сохранить путь (расширение step images).
* **Загрузка OG-изображения** (**ED-14, A-39**): локальный файл → `upload` в Storage (как `tools/import-games.mjs` `uploadImages`), сохранить путь как `shareImageUrl`. В минимальном варианте этой стори допустимо принимать только существующий путь/URL без upload — фиксируется в спецификации.
* **ED-8 (AC-02)**: поведение уже есть (проверка до публикации); повторная публикация с тем же slug и тем же `id` — допустима (перезапись), конфликт — только чужим `id`. Тест-прикрытие — Шаг 6.

### Шаг 5. Firestore Rules и публичный read

Правила не меняются: `game_public`, `scenario_public` — `allow read: if true`. В эмуляторе-тестах правил (`scenario-site/scripts/tc-rules.mjs`) добавить проверку: `read` публичного агрегата возвращает SEO-поля (TC-04). Деплой — **ADR-011**.

**Обратная совместимость**: после включения required возможно переимпортировать существующие фикстуры (dev, затем prod) для восстановления обязательных SEO-полей. В первый релиз без публичного сайта допускается временная `null`-толерантность клиента для старых записей (поле потребляет SSG из E4).

### Шаг 6. Тесты

Соответствие тест-кейсам `docs/product/test-cases/e1-expert-sharing-seo-fields.md` (TC-01…TC-04):

| TC  | Слой | Проверка | Где |
| --- | ---- | -------- | --- |
| TC-01 | integration/контракт | `scenario_public`/`game_public` несут SEO/share-поля; значения == введённым; `game_public` — обязательные `seoTitle`/`seoDescription` | Dart-контракт + импорт dev + JSON Schema |
| TC-02 | integration | уникальный `slug` принимается; сохранение до публикации успешно | импорт valid-фикстуры повторно (идемпотентно) |
| TC-03 | integration | дубль `slug` в другом документе → ошибка, не публикуется (ED-8) | импорт конфликта (2 сущности, один slug) |
| TC-04 | integration | игра в 2+ сценариях: `game_public` имеет собственные обязательные `seoTitle`/`seoDescription`; нет поля `borrowed_from_scenario`/автоподстановки | validate + импорт + Dart-контракт (от сценария) |

* Расширить `scenario/test/contract_test.dart`: (a) `GamePublic.fromJson` с обязательными `seoTitle`/`seoDescription` — отсутствие поля бросает исключение; (b) `ScenarioPublic` с обязательным `seoTitle`. Round-trip покрыт.
* Smoke: TC-01, TC-04. Регресс: TC-01…TC-04 при изменении §4.4/полей.
* Локальный прогон: `node tools/validate-game.mjs <file>` / `node tools/validate-scenario.mjs <file>` на всех фикстурах; негативные из `data/content/*/invalid/` — FAIL. Импорт E2E на dev — по `scenario-e2e`-шагу (`tools/import-all.mjs --project dev`).

## 5. Файлы

* `docs/product/specs/e1-expert-sharing-seo-fields.md` — **настоящий документ** (SP-E1-04).
* `docs/product/schemas/content-contract.schema.json` — JSON Schema (уточнение required `scenarioPublic.seoTitle`, `gamePublic.seoTitle/seoDescription`).
* `docs/product/test-cases/e1-expert-sharing-seo-fields.md` — тест-кейсы TC-01…TC-04 (существуют).
* `tools/validate-game.mjs`, `tools/validate-scenario.mjs` — валидаторы (required, plain text, длины, URL/путь).
* `tools/import-games.mjs`, `tools/import-scenario.mjs` — импорт (перенос SEO/шаринг уже есть; upload OG-картинки, ED-8 fixed).
* `data/content/{games,scenarios}/*.json` — фикстуры с SEO/шаринг-полями (обновление) + негативные в `invalid/`.
* `scenario/lib/data/contract/models.dart` — `ScenarioPublic`/`GamePublic` (required-поля).
* `scenario/test/contract_test.dart` — контрактные/«no-fallback»-тесты (расширение).
* `scenario/lib/data/contract/content_contract.dart`, `scenario/lib/supabase_config.dart` — пути/`supabasePublicUrl` (существуют).

## 6. Риски

* **Обратная совместимость required**: старые `game_public`/`scenario_public` без новых полей ломают строгий парсинг после активации required. Митиг: последовательный backfill (Шаг 4), временная `null`-толерантность до E4, активация required синхронно с полным импортом.
* **Автоподстановка «чужого» описания** (**ED-9**): риск подстановки в импорте игры. Митиг: `game_public.seoDescription` копируется только из `games`; TC-04 проверяет отсутствие.
* **Формат OG-картинки** (локальный файл vs путь vs URL): митиг — фиксируем путь/URL, локальный файл загружается в Storage.
* **Деплой правил отложен до ADR-011**: до деплоя публичный read в проде недоступен — приёмка AC-01 только в эмуляторе/dev.
* **Секреты** (Admin SDK, Supabase service) — только env/Secret, не в git (**A-40**).
* **UTM-метки не пишутся в этой стори** — если эксперт ожидает `utmCampaign` в агрегате → follow-up (E5).

## 7. Follow-up (вне scope)

* Страницы сайта (og:*, canonical, meta) потребляют данные полей — **US-E4-01**, **FR-W-2**.
* Шаринг в системе (share sheet, UTM) — **US-E5-01/US-E5-03**.
* Деплой Firestore Rules — **ADR-011**.

## 8. Доступы и блокеры

* Доступ к Firebase dev/prod (`scenario-ba26a`/`scenario-prod-491c`) и Supabase service-role для импорта/бэкфилла (вне git, **A-40**).
* Согласование имён/required-полей фиксируется в схеме контракта; деплой правил — **ADR-011**.

## 9. Verify

Соответствие критериям **US-E1-04**:

* **AC-01 (A-10c, FR-M-7, FR-W-2)** — TC-01: `scenario_public`/`game_public` содержат title/description/OG и читаются из данных (без хардкода). Для игры обязательные `seoTitle`/`seoDescription` присутствуют.
* **AC-02 (ED-8)** — TC-02/TC-03: уникальность `slug` проверяется до публикации; конфликт отклоняется до записи.
* **AC-03 (ED-9)** — TC-04: группа с 2+ сценариями имеет собственные заполненные SEO-поля, автоподстановка «чужого» описания отсутствует.

Критерий готовности: все фикстуры проходят `validate-*`; импорт на dev (Firestore+Storage) генерирует `scenario_public`/`game_public` с ожидаемыми SEO/шаринг-полями; контракт-тесты `contract_test.dart` (TC-01/TC-04) зелёные и соответствуют JSON Schema.

## 10. История изменений

| Дата  | Автор | Изменение |
| ----- | ----- | --------- |
| 2026-09-07 | AID | Первая версия (drafted): фиксация обязательных SEO-полей (game_public — ED-9), правило OG-изображения (путь/URL + supabasePublicUrl), валидация по ED-8/ED-9, тесты TC-01…TC-04. |