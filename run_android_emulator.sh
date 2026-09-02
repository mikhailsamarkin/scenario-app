#!/usr/bin/env bash
#
# run_android_emulator.sh — установить и запустить Android-сборку (dev/prod) на эмуляторе/устройстве одной командой.
#
# Использование:
#   ./run_android_emulator.sh                # dev (по умолчанию)
#   ./run_android_emulator.sh prod           # prod
#   ./run_android_emulator.sh dev --build    # сначала собрать dev
#   ./run_android_emulator.sh --device SERIAL
#   ./run_android_emulator.sh --help
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ENV="${1:-dev}"
BUILD=0
DEVICE=""

usage() {
  sed -n '2,10p' "$0"
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
    APK_PATH="${APK_PATH:-$SCRIPT_DIR/build/app/outputs/apk/dev/release/app-dev-release.apk}"
    BUNDLE_ID="com.scenario.scenario.dev"
    FLAVOR="dev"
    ;;
  prod)
    APK_PATH="${APK_PATH:-$SCRIPT_DIR/build/app/outputs/apk/prod/release/app-prod-release.apk}"
    BUNDLE_ID="com.scenario.scenario"
    FLAVOR="prod"
    ;;
  *)
    echo "Ошибка: окружение должно быть dev или prod" >&2
    exit 1
    ;;
esac

# MainActivity лежит в фиксированном package com.scenario.scenario
# (flavor меняет только applicationId, Kotlin-кода в src/dev нет),
# поэтому компонент для am start = bundleId/package.MainActivity.
ACTIVITY="$BUNDLE_ID/com.scenario.scenario.MainActivity"

# Пути к Android SDK (если adb/emulator не в PATH)
ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
if command -v adb >/dev/null 2>&1; then
  ADB="adb"
else
  ADB="$ANDROID_HOME/platform-tools/adb"
fi
if command -v emulator >/dev/null 2>&1; then
  EMULATOR="emulator"
else
  EMULATOR="$ANDROID_HOME/emulator/emulator"
fi

if [[ ! -x "$ADB" ]]; then
  echo "Ошибка: adb не найден ($ADB). Установите Android SDK или укажите ANDROID_HOME." >&2
  exit 1
fi

# 1. Сборка, если запрошена
if [[ "$BUILD" == "1" ]]; then
  # Передаём APP_ENV и anon-ключ Supabase, чтобы flavor и рантайм-конфиг совпадали.
  SUPABASE_KEY="$(cat "${SCRIPT_DIR}/key/sb_anon_${FLAVOR}.txt" 2>/dev/null || true)"
  echo "==> flutter build apk --flavor $FLAVOR --release --dart-define=APP_ENV=$FLAVOR"
  (cd "$SCRIPT_DIR" && flutter build apk --flavor "$FLAVOR" --release \
    --dart-define=APP_ENV="$FLAVOR" \
    --dart-define=SUPABASE_ANON_KEY_$(echo "$FLAVOR" | tr '[:lower:]' '[:upper:]')="$SUPABASE_KEY")
fi

# 2. Проверка наличия APK
if [[ ! -f "$APK_PATH" ]]; then
  echo "Ошибка: не найден APK: $APK_PATH" >&2
  echo "Соберите его: flutter build apk --flavor $FLAVOR --release" >&2
  exit 1
fi

# 3. Выбор устройства: переданное, либо уже подключённое
if [[ -z "$DEVICE" ]]; then
  DEVICE="$("$ADB" devices | awk 'NR>1 && $2=="device" {print $1; exit}')"
fi

# 4. Если устройства нет — запустить эмулятор
if [[ -z "$DEVICE" ]]; then
  if [[ ! -x "$EMULATOR" ]]; then
    echo "Ошибка: нет подключённых устройств и emulator не найден ($EMULATOR)" >&2
    exit 1
  fi

  AVD="$("$EMULATOR" -list-avds 2>/dev/null | head -n 1 || true)"

  # 4a. Если AVD нет — попробовать создать автоматически
  if [[ -z "$AVD" ]]; then
    echo "==> AVD не найден, пробую создать"

    # Java для avdmanager/sdkmanager: сначала JBR от Android Studio,
    # иначе /usr/bin/java (stub macOS) зависает на «Unable to locate a Java Runtime»
    JAVA_BIN=""
    if [[ -x "/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java" ]]; then
      JAVA_BIN="/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/java"
    elif command -v java >/dev/null 2>&1; then
      JAVA_BIN="$(command -v java)"
    fi
    if [[ -z "$JAVA_BIN" ]]; then
      echo "Ошибка: java не найден. Установите JDK или Android Studio." >&2
      exit 1
    fi
    export JAVA_HOME="$(cd "$(dirname "$JAVA_BIN")/.." && pwd)"

    AVDMANAGER="$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager"
    if [[ ! -x "$AVDMANAGER" ]]; then
      AVDMANAGER="$(find "$ANDROID_HOME/cmdline-tools" -name avdmanager -type f 2>/dev/null | head -n 1 || true)"
    fi
    if [[ -z "$AVDMANAGER" ]]; then
      echo "Ошибка: avdmanager не найден. Установите Android cmdline-tools." >&2
      exit 1
    fi
    SDKMANAGER="$(dirname "$AVDMANAGER")/sdkmanager"

    # Выбрать уже установленный system image, иначе попробовать скачать
    IMAGE=""
    for cand in \
      "system-images;android-36;google_apis;arm64-v8a" \
      "system-images;android-34;google_apis;arm64-v8a" \
      "system-images;android-36;google_apis_playstore;arm64-v8a"; do
      if [[ -d "$ANDROID_HOME/$cand" ]]; then
        IMAGE="$cand"
        break
      fi
    done

    if [[ -z "$IMAGE" ]]; then
      IMAGE="system-images;android-36;google_apis;arm64-v8a"
      echo "==> System image не установлен, скачиваю $IMAGE (может занять время)"

      # Прямое скачивание через curl с прогресс-баром (sdkmanager не показывает прогресс)
      REPO_URL="https://dl.google.com/android/repository/sys-img/google_apis"
      ZIP_NAME="arm64-v8a-36_r07.zip"
      ZIP_PATH="$ANDROID_HOME/.temp/$ZIP_NAME"
      # Package path (system-images;android-36;google_apis;arm64-v8a) → реальный путь (system-images/android-36/google_apis/arm64-v8a)
      IMAGE_PARENT="$ANDROID_HOME/${IMAGE//;//}"
      # zip содержит вложенную папку arm64-v8a/, поэтому распаковываем на уровень выше,
      # чтобы вложенная arm64-v8a/ легла точно в ожидаемое avdmanager место
      IMAGE_DIR="$(dirname "$IMAGE_PARENT")"
      mkdir -p "$ANDROID_HOME/.temp" "$IMAGE_DIR"

      echo "==> Скачиваю $ZIP_NAME (~1.9 ГБ)"
      if ! curl -fL --progress-bar -o "$ZIP_PATH" "$REPO_URL/$ZIP_NAME"; then
        echo "Ошибка: не удалось скачать $REPO_URL/$ZIP_NAME" >&2
        exit 1
      fi

      echo "==> Распаковываю в $IMAGE_DIR"
      if ! unzip -q -o "$ZIP_PATH" -d "$IMAGE_DIR"; then
        echo "Ошибка: не удалось распаковать $ZIP_PATH" >&2
        exit 1
      fi
      rm -f "$ZIP_PATH"
    fi

    echo "==> Создаю AVD: scenario ($IMAGE)"
    echo no | "$AVDMANAGER" create avd -n scenario -k "$IMAGE" -d pixel_7 >/dev/null 2>&1 || true
    AVD="scenario"
  fi

  echo "==> Запускаю эмулятор: $AVD"
  nohup "$EMULATOR" -avd "$AVD" >/dev/null 2>&1 &
  echo "==> Ожидаю загрузку устройства"
  "$ADB" wait-for-device
  for _ in $(seq 1 120); do
    if [[ "$("$ADB" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]]; then
      break
    fi
    sleep 2
  done
  DEVICE="$("$ADB" devices | awk 'NR>1 && $2=="device" {print $1; exit}')"
fi

if [[ -z "$DEVICE" ]]; then
  echo "Ошибка: устройство не найдено" >&2
  exit 1
fi

echo "==> Устройство: $DEVICE"

# 5. Установка
echo "==> Устанавливаю $APK_PATH"
"$ADB" -s "$DEVICE" install -r "$APK_PATH"

# 6. Запуск
echo "==> Запускаю $ACTIVITY"
"$ADB" -s "$DEVICE" shell am start -n "$ACTIVITY"

echo "Готово. Приложение запущено на устройстве $DEVICE."