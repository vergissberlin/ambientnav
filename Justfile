# AmbientNav development shortcuts
# https://github.com/casey/just

app_dir := "app"
ui_dir := "packages/ambientnav_ui"
widgetbook_dir := "widgetbook"
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

# --- Design system & component catalogue ---

# Install dependencies for the UI package and the catalogue too
prepare-all: prepare
    cd {{ui_dir}} && flutter pub get
    cd {{widgetbook_dir}} && flutter pub get

# Run the component catalogue (chrome | macos | linux)
widgetbook device="chrome":
    cd {{widgetbook_dir}} && flutter run -d {{device}}

# Pump every registered use case
widgetbook-test:
    cd {{widgetbook_dir}} && flutter test

# Static web build, as published by CI
widgetbook-build:
    cd {{widgetbook_dir}} && flutter build web --base-href /ambientnav/widgetbook/

# Tokens + brand atoms
ui-test:
    cd {{ui_dir}} && flutter test

# Regenerate the brand-atom golden images.
# Ubuntu is authoritative — CI verifies these on ubuntu-latest, and macOS
# antialiasing differs. Run this on Linux or let CI report the diff.
goldens:
    cd {{ui_dir}} && flutter test --update-goldens test/golden

# Format every Dart package the way CI checks it
fmt:
    cd {{app_dir}} && dart format lib test integration_test
    cd {{ui_dir}} && dart format lib test
    cd {{widgetbook_dir}} && dart format lib test

# Everything CI runs, locally
check:
    cd {{app_dir}} && dart format --set-exit-if-changed lib test integration_test
    cd {{app_dir}} && flutter analyze && flutter test
    cd {{ui_dir}} && dart format --set-exit-if-changed lib test
    cd {{ui_dir}} && flutter analyze && flutter test
    cd {{widgetbook_dir}} && dart format --set-exit-if-changed lib test
    cd {{widgetbook_dir}} && flutter analyze && flutter test
