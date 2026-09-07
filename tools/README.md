# tools — скрипты импорта контента

Сюда помещаются скрипты (например Node + Firebase Admin SDK) для загрузки JSON из `data/content/` в Firestore и файлов в Supabase Storage.

- Рабочий процесс и промпт для Cursor: [docs/content-import-prompt.md](../docs/content-import-prompt.md)
- Решения по продукту: [docs/engineering-decisions-and-open-questions.md](../docs/engineering-decisions-and-open-questions.md) (**ED-4**)
- Спецификация реализации: [docs/product/specs/e1-expert-create-game-carousel.md](../docs/product/specs/e1-expert-create-game-carousel.md) (**SP-E1-01**)
- Спецификация реализации: [docs/product/specs/e1-expert-scenario-games-order-short-description.md](../docs/product/specs/e1-expert-scenario-games-order-short-description.md) (**SP-E1-03**)

Секреты учётных записей Firebase не хранить в репозитории (СТ **A-40**).

## Скрипты

| Скрипт | Назначение |
|--------|------------|
| `validate-game.mjs` | Валидатор игры: enum-allowlist (CR-4.1), карусель (CR-5, ≥1 `teaser`), обязательные поля (A-30), plain text (A-4a). CLI: `node validate-game.mjs <game.json>` |
| `validate-scenario.mjs` | Валидатор сценария и связок: обязательные поля, порядок (CR-4, уникальный `order`), `shortDescription` plain text (A-4a), ссылочная целостность `gameId`. CLI: `node validate-scenario.mjs <scenario.json>` |
| `import-games.mjs` | Импорт/публикация одной игры: валидация → slug-уникальность (ED-8) → upload в Supabase Storage (ED-7) → запись `games/{id}` → сборка `game_public` (A-10) → обновление `home_feed`/`sitemap_public`. CLI: `node import-games.mjs --project dev\|prod <game.json> [--dry-run]` |
| `import-scenario.mjs` | Импорт/публикация одного сценария со связками: валидация → slug-уникальность (ED-8) → запись `scenarios/{id}` → синхронизация `scenario_games` → сборка `scenario_public` (A-10) → обновление `game_public.scenarios` (A-12). CLI: `node import-scenario.mjs --project dev\|prod <scenario.json> [--dry-run]` |
| `import-all.mjs` | Оркестратор импорта всех фикстур (игр и сценариев): валидирует `data/content/games/*.json` и `data/content/scenarios/*.json` (кроме `invalid/`) без секретов, затем импортирует каждую на выбранный проект (замена CI-прогона). CLI: `node import-all.mjs --project dev [--dry-run]` |
| `make-mock-images.py` | Генерация mock-изображений (PNG) для фикстур; конвертация в JPEG — через `sips` |

## Запуск

```bash
# Установка зависимостей (один раз)
cd tools && npm install

# Валидация фикстур
node tools/validate-game.mjs data/content/games/munchkin.json
node tools/validate-scenario.mjs data/content/scenarios/vecherinka.json

# Unit-тесты валидаторов (TC-01..TC-03, A-30, A-4a)
cd tools && node --test test/validate-game.test.mjs test/validate-scenario.test.mjs

# Импорт на dev (dry-run — без записи)
FIREBASE_SERVICE_ACCOUNT_PATH=/path/to/service-account.json \
SUPABASE_URL=https://<project>.supabase.co \
SUPABASE_SERVICE_ROLE_KEY=<key> \
node tools/import-games.mjs --project dev data/content/games/munchkin.json --dry-run

# Импорт на dev (реальная запись)
FIREBASE_SERVICE_ACCOUNT_PATH=/path/to/service-account.json \
SUPABASE_URL=https://<project>.supabase.co \
SUPABASE_SERVICE_ROLE_KEY=<key> \
node tools/import-games.mjs --project dev data/content/games/munchkin.json

# Импорт всех фикстур на dev (валидация + импорт каждой; dry-run — без записи)
FIREBASE_SERVICE_ACCOUNT_PATH=/path/to/service-account.json \
SUPABASE_URL=https://<project>.supabase.co \
SUPABASE_SERVICE_ROLE_KEY=<key> \
node tools/import-all.mjs --project dev --dry-run

# То же через npm-скрипт (без --dry-run)
cd tools && npm run import:dev
```

## Mock-данные для проверки

- `data/content/games/munchkin.json` — валидная игра (карусель с `teaser`), ссылается на `images/teaser.jpg` и `images/box.jpg`.
- `data/content/games/munchkin-no-teaser.json` — невалидная (нет `teaser`) — для TC-02.
- `data/content/games/munchkin-bad-enum.json` — невалидная (enum вне allowlist) — для TC-03.
- `data/content/games/images/` — mock-изображения (JPEG 640×360), генерируются заново: `python3 tools/make-mock-images.py` + `sips -s format jpeg ...`.
- `data/content/scenarios/vecherinka.json` — валидный сценарий со связкой игры `munchkin` (порядок, `shortDescription`).
- `data/content/scenarios/invalid/vecherinka-bad-order.json` — невалидный (дубль `order` и дубль `gameId`) — для TC-02.

Переменные окружения (вне git, **A-40**): `FIREBASE_SERVICE_ACCOUNT_PATH`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` (по окружению dev/prod).