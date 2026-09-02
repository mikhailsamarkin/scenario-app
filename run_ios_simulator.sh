#!/usr/bin/env bash
#
# run_ios_simulator.sh — установить и запустить iOS-приложение в Simulator одной командой.
#
# Использование:
#   ./run_ios_simulator.sh                # dev (по умолчанию)
#   ./run_ios_simulator.sh prod           # prod
#   ./run_ios_simulator.sh dev --build    # сначала собрать dev
#   ./run_ios_simulator.sh --device UDID  # запустить на конкретном симуляторе
#   ./run_ios_simulator.sh --help
#
# Примечание: bundle id у dev и prod разные (dev = com.scenario.scenario.dev,
# prod = com.scenario.scenario); build phase подставляет GoogleService-Info.plist по $FLAVOR.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUNDLE_ID=""

ENV="${1:-dev}"
BUILD=0
DEVICE=""

usage() {
  sed -n '2,11p' "$0"
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    dev|prod) ENV="$1"; shift ;;
    --build) BUILD=1; shift ;;
    --device) DEVICE="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Неизвестный аргумент: $1" >&2; usage ;;
  esac
done

case "$ENV" in
  dev)
    APP_PATH="${APP_PATH:-$SCRIPT_DIR/build/ios/iphonesimulator/Runner.app}"
    FLAVOR="dev"
    BUNDLE_ID="com.scenario.scenario.dev"
    ;;
  prod)
    APP_PATH="${APP_PATH:-$SCRIPT_DIR/build/ios/iphonesimulator/Runner.app}"
    FLAVOR="prod"
    BUNDLE_ID="com.scenario.scenario"
    ;;
  *)
    echo "Ошибка: окружение должно быть dev или prod" >&2
    exit 1
    ;;
esac

# 1. Сборка, если запрошена
if [[ "$BUILD" == "1" ]]; then
  # Передаём APP_ENV и anon-ключ Supabase, чтобы flavor и рантайм-конфиг совпадали.
  SUPABASE_KEY="$(cat "${SCRIPT_DIR}/key/sb_anon_${FLAVOR}.txt" 2>/dev/null || true)"
  echo "==> flutter build ios --simulator --flavor $FLAVOR --dart-define=APP_ENV=$FLAVOR"
  (cd "$SCRIPT_DIR" && flutter build ios --simulator --flavor "$FLAVOR" \
    --dart-define=APP_ENV="$FLAVOR" \
    --dart-define=SUPABASE_ANON_KEY_$(echo "$FLAVOR" | tr '[:lower:]' '[:upper:]')="$SUPABASE_KEY")
fi

# 2. Проверка наличия собранного .app
if [[ ! -d "$APP_PATH" ]]; then
  echo "Ошибка: не найден собранный app: $APP_PATH" >&2
  echo "Соберите его: flutter build ios --simulator" >&2
  exit 1
fi

# 3. Открыть Simulator
echo "==> Открываю Simulator"
open -a Simulator

# 4. Выбрать устройство: уже запущенное, либо первый доступный iPhone
if [[ -z "$DEVICE" ]]; then
  DEVICE="$(xcrun simctl list devices booted | grep -Eo '[0-9A-F-]{36}' | head -n 1 || true)"
fi

if [[ -z "$DEVICE" ]]; then
  DEVICE="$(xcrun simctl list devices available | grep -E 'iPhone' | head -n 1 | grep -Eo '[0-9A-F-]{36}')"
fi

if [[ -z "$DEVICE" ]]; then
  echo "Ошибка: не найден доступный iPhone-симулятор" >&2
  exit 1
fi

echo "==> Устройство: $DEVICE"
xcrun simctl bootstatus "$DEVICE" -b

# 5. Установка
echo "==> Устанавливаю $APP_PATH"
xcrun simctl install "$DEVICE" "$APP_PATH"

# 6. Запуск
echo "==> Запускаю $BUNDLE_ID"
xcrun simctl launch "$DEVICE" "$BUNDLE_ID"

echo "Готово. Приложение запущено на симуляторе $DEVICE."