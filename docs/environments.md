# Окружения Scenario — dev / prod

> Mapping: ветка → проект → сборка → команды (Firebase + Supabase).
> Обновлено: 2026-08-31 (US-E0-02).

## 1. Таблица окружений

| | **dev** | **prod** |
|---|---|---|
| Firebase project | `scenario-ba26a` | `scenario-prod-491c` |
| Firebase project number | `602717699795` | `268811118114` |
| Firestore region | europe-west1 | europe-west1 |
| Supabase project | `bzraqbhydmklvpfqiidl` | `sjxmmqnejolgtwcfjzsd` |
| Supabase region | Central EU (Frankfurt) | Central EU (Frankfurt) |
| Supabase bucket | `games` | `games` |
| Flutter flavor | `dev` | `prod` |
| Android applicationId | `com.scenario.scenario.dev` | `com.scenario.scenario` |
| iOS bundle id | `com.scenario.scenario` | `com.scenario.scenario` |
| App label | Scenario Dev | Scenario |
| Сайт (NEXT_PUBLIC_ENV) | `dev` (default) | `prod` |

## 2. Ветка → окружение

| Ветка | Окружение | Что деплоится |
|---|---|---|
| `main` | prod | prod-сборки (App Store / Play / сайт) |
| `dev` / feature-ветки | dev | dev-сборки, тесты |

## 3. Flutter

### Сборка Android

```bash
# dev
flutter build apk --flavor dev
# prod
flutter build apk --flavor prod
```

### Сборка iOS

```bash
# dev (симулятор, без подписи)
flutter build ios --simulator --flavor dev
# prod (симулятор)
flutter build ios --simulator --flavor prod
# на устройство — требует Apple Developer сертификаты
flutter build ios --flavor prod
```

### Запуск

```bash
# dev (ключ из key/sb_anon_dev.txt или .env.local)
flutter run --dart-define=APP_ENV=dev --dart-define=SUPABASE_ANON_KEY_DEV="$(cat key/sb_anon_dev.txt)"
# prod
flutter run --dart-define=APP_ENV=prod --dart-define=SUPABASE_ANON_KEY_PROD="$(cat key/sb_anon_prod.txt)"
```

### Конфигурация

- `APP_ENV=dev|prod` — выбор окружения (default dev).
- `SUPABASE_ANON_KEY_DEV` / `SUPABASE_ANON_KEY_PROD` — anon-ключи Supabase.
- Firebase options: `lib/firebase_options_dev.dart` / `lib/firebase_options_prod.dart`.
- Android: `android/app/src/dev/google-services.json` / `src/prod/google-services.json` (вне git).
- iOS: `ios/Runner/GoogleService-Info-Dev.plist` / `-Prod.plist` (вне git); build phase подставляет по `$FLAVOR`.

## 4. Сайт (scenario-site)

### Переменные окружения (`.env.local`, вне git)

| Переменная | dev | prod |
|---|---|---|
| `NEXT_PUBLIC_ENV` | `dev` (default) | `prod` |
| `NEXT_PUBLIC_FIREBASE_API_KEY` | dev | `..._PROD` |
| `NEXT_PUBLIC_FIREBASE_PROJECT_ID` | `scenario-ba26a` | `scenario-prod-491c` |
| `NEXT_PUBLIC_SUPABASE_URL` | `https://bzraqbhydmklvpfqiidl.supabase.co` | `https://sjxmmqnejolgtwcfjzsd.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | dev | `..._PROD` |

### Сборка

```bash
cd scenario-site
npm install
npm run build   # next build (SSG, output: export)
```

### Деплой Firebase (rules)

```bash
export XDG_CONFIG_HOME=/tmp/fb-config   # обход EPERM песочницы
firebase deploy --only firestore:rules --project scenario-ba26a        # dev
firebase deploy --only firestore:rules --project scenario-prod-491c    # prod
```

## 5. Supabase

### Бакет games

- Создан в обоих проектах: public, file_size_limit 10MB, allowed_mime_types image/jpeg|png|webp.
- Policy `public_read_games` (SELECT для public) — публичное чтение (A-39).
- Запись — только service_role (импорт контента, follow-up).

### Ключи

| Ключ | Где |
|---|---|
| anon dev / prod | `scenario-site/.env.local`, `key/sb_anon_dev.txt`, `key/sb_anon_prod.txt` |
| service_role dev / prod | `key/sb_sr_dev.txt`, `key/sb_sr_prod.txt` (вне git) |
| PAT (Management API) | `key/supabase-token` |

## 6. Ежедневный push (A-7)

- **Вариант C (без Cloud Functions):** GitHub Actions cron `scenario-site/.github/workflows/daily-push.yml` → `scripts/daily-push.mjs` (firebase-admin → Firestore + FCM).
- Cron: `0 8 * * *` (08:00 UTC = 11:00 МСК).
- GitHub Secrets: `FIREBASE_SERVICE_ACCOUNT` (JSON), опционально `FCM_TOPIC` (default `daily`).
- Функция `dailyPush` в `functions/` — задел на будущее (деплой требует Blaze, стори E3).

## 7. CI

- `scenario/.github/workflows/ci.yml`: gitleaks + `flutter build apk --flavor dev`.
- GitHub Secret: `GOOGLE_SERVICES_JSON_DEV` (google-services dev).

## 8. Секреты — сводка

| Секрет | Путь / Secret | В git? |
|---|---|---|
| Firebase Android dev | `scenario/android/app/src/dev/google-services.json` | нет |
| Firebase Android prod | `scenario/android/app/src/prod/google-services.json` | нет |
| Firebase iOS dev | `scenario/ios/Runner/GoogleService-Info-Dev.plist` | нет |
| Firebase iOS prod | `scenario/ios/Runner/GoogleService-Info-Prod.plist` | нет |
| Supabase anon dev/prod | `scenario-site/.env.local` | нет |
| Supabase service_role dev/prod | `key/sb_sr_dev.txt`, `key/sb_sr_prod.txt` | нет |
| Firebase service account (CI) | GitHub Secret `FIREBASE_SERVICE_ACCOUNT` | нет |
| google-services dev (CI) | GitHub Secret `GOOGLE_SERVICES_JSON_DEV` | нет |
| DAILY_PUSH_SECRET (будущее) | `scenario-site/functions/.env` | нет |