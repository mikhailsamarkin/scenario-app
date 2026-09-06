---
title: "Руководство по загрузке контента (игры)"
doc_id: CONTENT-IMPORT-GUIDE
status: drafted
updated: "2026-09-06"
---

# User Guide: Загрузка контента (игры)

## Introduction

Это руководство для эксперта: как загрузить собственную игру в Scenario без админки — через репозиторий и скрипты импорта (**ED-4**, **SP-E1-01**). После загрузки игра публикуется в Firestore и Supabase Storage и становится доступна в МП и на сайте.

**Что понадобится:**

- Доступ к репозиторию `scenario` (файлы + терминал).
- Node.js ≥ 18.
- Учётные данные для импорта (вне репозитория, **A-40**):
  - `FIREBASE_SERVICE_ACCOUNT_PATH` — путь к service account key Firebase;
  - `SUPABASE_URL` и `SUPABASE_SERVICE_ROLE_KEY` — по окружению dev/prod.

## Getting started

### Step 1: Подготовить JSON игры

Создай файл, например `scenario/data/content/games/my-game.json`:

```json
{
  "id": "my-game",
  "slug": "my-game",
  "title": "Моя игра",
  "playersHint": "players_2_5",
  "durationBucket": "evening",
  "ageHint": "age_family",
  "rulesComplexity": "normal",
  "carousel": [
    {
      "imageRef": "images/my-teaser.jpg",
      "frameType": "teaser",
      "caption": "Коробка",
      "alt": "Коробка игры Моя игра"
    },
    {
      "imageRef": "images/my-box.jpg",
      "frameType": "box",
      "alt": "Игровой процесс"
    }
  ]
}
```

**Правила полей:**

| Поле | Обязательно | Допустимые значения / примечание |
|------|-------------|----------------------------------|
| `id` | да | Стабильный идентификатор (латиница, без пробелов); станет `games/{id}` и `game_public/{id}` |
| `slug` | да | URL; **уникален** в коллекции `games` (ED-8) |
| `title` | да | Plain text, без Markdown/HTML (A-4a) |
| `playersHint` | да | `players_1`, `players_2`, `players_2_4`, `players_2_5`, `players_2_6`, `players_5_plus` |
| `durationBucket` | да | `warmup`, `short`, `evening`, `long`, `main_event` |
| `ageHint` | да | `age_kids`, `age_family`, `age_adults` |
| `rulesComplexity` | да | `easy`, `normal`, `heavy` |
| `carousel` | да | Непустой массив; **минимум один слайд с `frameType: "teaser"`** (CR-5) |
| `seoTitle`, `seoDescription` | нет | Заполнение — US-E1-04 |

**Слайд карусели:**

| Поле | Обязательно | Примечание |
|------|-------------|------------|
| `imageRef` | да | Локальный путь относительно JSON или уже загруженный путь в Storage (`games/{id}/...`) |
| `frameType` | да | `teaser`, `box`, `in_play`, `mechanic_closeup` |
| `caption` | нет | Plain text |
| `alt` | нет | Plain text; для SEO/доступности (CR-5) |

### Step 2: Положить изображения

`imageRef` — локальный путь **относительно JSON-файла**. Для примера выше:

```
scenario/data/content/games/my-game.json
scenario/data/content/games/images/my-teaser.jpg
scenario/data/content/games/images/my-box.jpg
```

Ограничения (лимиты бакета `games`, SP-E0-02): **JPEG/PNG/WebP**, **≤ 10MB**. Скрипт проверит наличие, формат и размер до загрузки.

Если изображение уже лежит в Storage (путь `games/{id}/...`), можно указать его напрямую — скрипт пропустит повторный upload.

### Step 3: Проверить валидатором

```bash
node scenario/tools/validate-game.mjs scenario/data/content/games/my-game.json
```

Ожидаешь `OK: ... — игра валидна`. Ошибки покажут, что поправить (например, «carousel: требуется минимум один слайд с frameType=teaser»).

### Step 4: Запустить импорт

```bash
FIREBASE_SERVICE_ACCOUNT_PATH=/path/to/service-account.json \
SUPABASE_URL=https://<project>.supabase.co \
SUPABASE_SERVICE_ROLE_KEY=<key> \
node scenario/tools/import-games.mjs --project dev scenario/data/content/games/my-game.json
```

- `--project dev` → Firebase `scenario-ba26a` + **dev**-ключи Supabase; `--project prod` → `scenario-prod-491c` + **prod**-ключи.
- Сначала попробуй с `--dry-run` — скрипт пройдёт все проверки и покажет план, ничего не записав.
- Повторный запуск с теми же данными **идемпотентен** — обновит документы по `id`, дубликатов не создаст.

**Что произойдёт при импорте:**

1. Валидация JSON (enum CR-4.1, карусель CR-5, обязательные поля A-30).
2. Проверка уникальности `slug` (ED-8).
3. Upload изображений в Supabase Storage: `games/{id}/<filename>` (ED-7, A-39).
4. Запись `games/{id}` — источник правды (закрыт для клиентского read, A-38).
5. Сборка `game_public/{gameId}` — публичный агрегат (A-10).
6. Обновление `home_feed.carousel` и `sitemap_public.gameSlugs` (A-10e, A-44).

## Features

### Валидация полей

- Enum-поля принимают только ключи из allowlist (CR-4.1); неизвестное значение — ошибка, запись не выполняется.
- Карусель обязана содержать минимум один слайд `teaser` (CR-5).
- Тексты — plain text, без Markdown/HTML (A-4a).

### Публикация и публичный read

- После импорта игра доступна клиентам через `game_public/{gameId}` по правилам Firestore (A-38).
- Изображения доступны по публичным URL Supabase Storage (A-39).
- Деплой правил в прод — ADR-011 (до деплоя Firestore закрыт целиком).

### CI-импорт

Workflow `scenario/.github/workflows/import-content.yml` автоматически валидирует фикстуры из `data/content/games/` и импортирует их на dev-проект при пуше в эти пути. Секреты — из GitHub Secrets (A-40).

## FAQ

### Можно ли обновить уже загруженную игру?

Да. Повторный запуск импорта с тем же `id` обновляет документы (`games/{id}`, `game_public/{gameId}`, агрегаты) — идемпотентно.

### Что делать, если slug занят?

Импорт упадёт с ошибкой «slug ... уже занят документом games/{id}». Нужно выбрать другой `slug` или удалить/переименовать существующую игру.

### Можно ли загрузить изображение, которое уже в Storage?

Да. Укажи в `imageRef` путь `games/{id}/<filename>` — скрипт пропустит повторный upload.

### Какие форматы и размеры изображений допустимы?

JPEG/PNG/WebP, ≤ 10MB (лимит бакета `games`).

## Troubleshooting

| Problem | Solution |
| ------- | -------- |
| `carousel: требуется минимум один слайд с frameType=teaser` | Добавь слайд с `"frameType": "teaser"` |
| `playersHint: допустимые значения: ...` | Проверь enum-ключ по таблице в Step 1 |
| `Изображение не найдено: ...` | Проверь путь `imageRef` относительно JSON-файла |
| `Неподдерживаемый формат изображения` | Используй JPEG/PNG/WebP |
| `Изображение превышает 10MB` | Уменьши файл |
| `slug ... уже занят` | Выбери другой `slug` |
| `FIREBASE_SERVICE_ACCOUNT_PATH не задан` | Задай env-переменные (A-40) |

## Glossary

| Term | Definition |
| ---- | ---------- |
| `imageRef` | Ссылка на изображение слайда: локальный путь или путь в Supabase Storage |
| `frameType` | Тип кадра слайда: `teaser`, `box`, `in_play`, `mechanic_closeup` |
| `game_public` | Публичный агрегат игры, читаемый МП и сайтом |
| `home_feed` | Публичный агрегат главного экрана (карусель, витрина, группы) |
| `sitemap_public` | Индекс опубликованных slug для SSG |
| `--dry-run` | Флаг импорта: проверка без записи в Firestore/Storage |