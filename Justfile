# AmbientNav development shortcuts
# https://github.com/casey/just

app_dir := "app"
mock := "--dart-define=USE_MOCK=true"
default_sim := "iPhone 17"

default:
    @just run

# Install dependencies and regenerate localizations
prepare:
    cd {{app_dir}} && flutter pub get && flutter gen-l10n

# Run on an iOS simulator with mock BLE (boots default_sim if none is running)
run device=default_sim:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{app_dir}}"
    flutter pub get
    if ! xcrun simctl list devices | grep -F "{{device}}" | grep -q "(Booted)"; then
      echo "Starting simulator: {{device}}…"
      xcrun simctl boot "{{device}}" 2>/dev/null || true
      open -a Simulator
      sleep 2
    fi
    exec flutter run -d "{{device}}" {{mock}}

# Run on a connected physical iPhone (pass device id/name, or auto-pick the first iOS device)
phone device="":
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{app_dir}}"
    flutter pub get
    if [[ -n "{{device}}" ]]; then
      exec flutter run -d "{{device}}" {{mock}}
    fi
    line="$(flutter devices 2>/dev/null | grep ' ios ' | grep -v simulator | head -1 || true)"
    if [[ -z "${line}" ]]; then
      echo "No physical iOS device found. Connect an iPhone and enable Developer Mode."
      flutter devices
      exit 1
    fi
    ios_id="$(echo "${line}" | awk -F '•' '{gsub(/^ +| +$/, "", $2); print $2}')"
    exec flutter run -d "${ios_id}" {{mock}}

# Open the iOS Simulator app
sim:
    open -a Simulator

# Boot a simulator without running the app
sim-boot device=default_sim:
    xcrun simctl boot "{{device}}" 2>/dev/null || true
    open -a Simulator

# Static analysis and unit/widget tests
analyze:
    cd {{app_dir}} && flutter analyze

test:
    cd {{app_dir}} && flutter test
