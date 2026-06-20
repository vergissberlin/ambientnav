---
title: "Entwicklungsumgebung"
description: "Lokale Entwicklungsumgebung für AmbientNav einrichten — Tools, Abhängigkeiten und erster Start."
---

## Benötigte Tools

Installiere alle folgenden Tools, bevor du versuchst, einen Teil des Projekts zu bauen.

| Tool | Mindestversion | Zweck |
|---|---|---|
| Flutter | 3.27.0 | App-Build und Tests |
| Dart | 3.6.0 | Inklusive Flutter |
| FVM | beliebig | (Optional) Pinnt die Flutter-Version pro Projekt |
| Xcode | 15.0 | iOS-Simulator und Archive — nur macOS |
| Android SDK | API 33 (Android 13) | Android-Builds und Emulator |
| PlatformIO Core | 6.1 | Firmware-Build und Flash |
| Node.js | 20.0 | Docs-Site-Build (Astro/Starlight) |
| `just` | 1.13 | Projekt-Task-Runner |

### `just` installieren

```bash
# macOS
brew install just

# Linux (cargo)
cargo install just

# Windows (winget)
winget install --id Casey.Just
```

:::tip
Verwende [FVM (Flutter Version Manager)](https://fvm.app/), um die genaue Flutter-Version anzupinnen, die in `.fvm/fvm_config.json` angegeben ist. Damit stellen alle Entwickler und CI dieselbe SDK-Revision sicher.

```bash
# FVM installieren
dart pub global activate fvm

# Im Repo — gepinnte Version installieren und aktivieren
fvm install
fvm use

# Flutter-Befehle dann mit Präfix aufrufen:
fvm flutter pub get
fvm flutter test
```

Oder füge `fvm flutter` als Alias in deinem Shell-Profil hinzu.
:::

:::note
**Xcode ist nur unter macOS verfügbar.** iOS-Simulator und Archive-Builds sind unter Linux oder Windows nicht möglich. Du kannst trotzdem das Android APK bauen, die Firmware entwickeln und die Docs-Site auf jeder Plattform betreiben. iOS-Beitragende benötigen einen Mac mit macOS 14 (Sonoma) oder neuer.
:::

## Repository klonen

```bash
git clone https://github.com/your-org/ambientnav.git
cd ambientnav
```

## Flutter App-Abhängigkeiten

```bash
cd app
flutter pub get
flutter gen-l10n
```

`flutter gen-l10n` generiert die Lokalisierungsklassen aus den ARB-Dateien in `app/lib/l10n/`. Du musst es erneut ausführen, nachdem du eine `.arb`-Datei hinzugefügt oder bearbeitet hast.

## App ohne Hardware ausführen

Die App läuft in einem vollständig gemockten BLE-Modus — kein ESP32 erforderlich. `MockControllerRepository` liefert simulierte Navigationsbefehle, Proximity-Sensordaten und Telemetrie-Streams.

```bash
# Mit dem just-Task-Runner (empfohlen)
just run

# Oder direkt mit flutter
flutter run --dart-define=USE_MOCK=true
```

Damit startet die App auf dem standardmäßig verbundenen Gerät oder Emulator mit aktiviertem Mock-BLE. Alle UI-Abläufe — Navigation, Einparkhilfe, LED-Konfiguration, Einstellungen — sind voll funktionsfähig.

## Auf einem physischen Gerät ausführen

Um auf einem echten Smartphone mit verbundenem ESP32 (BLE-Hardware vorhanden) zu testen:

```bash
just phone
# Entspricht:
# flutter run --dart-define=USE_MOCK=false
```

Stelle sicher, dass Bluetooth auf dem Smartphone aktiviert und die ESP32-Vorderplatine eingeschaltet ist, bevor du die App startest.

## Firmware: Mit PlatformIO bauen

Jedes Firmware-Verzeichnis ist ein eigenständiges PlatformIO-Projekt.

```bash
# Vorderplatinen-Firmware bauen
cd firmware/front
pio run

# Hinterplatinen-Firmware bauen
cd firmware/rear
pio run
```

PlatformIO lädt beim ersten Build automatisch alle deklarierten Bibliotheksabhängigkeiten herunter. Der erste Build dauert 2–4 Minuten.

## Docs-Site: Lokale Entwicklung

```bash
cd docs
npm install
npm run dev
```

Die Starlight-Site startet auf `http://localhost:4321`. Änderungen an Markdown-Dateien werden im Browser sofort neu geladen.

So überprüfst du, ob der Produktions-Build fehlerfrei kompiliert:

```bash
npm run build
```

## Alle Tests ausführen

```bash
# Mit just (vom Repository-Root)
just test

# Oder direkt im App-Verzeichnis
cd app
flutter test
```

Tests für ein einzelnes Feature ausführen:

```bash
cd app
flutter test test/features/ble/
```

## Statische Analyse

```bash
# Mit just (vom Repository-Root)
just analyze

# Oder direkt
cd app
flutter analyze
```

Die Analyse verwendet die Regeln in `app/analysis_options.yaml`. Alle Warnungen werden in CI als Fehler behandelt — behebe sie, bevor du pushst.

## Verfügbare `just`-Befehle

Das `justfile` im Repository-Root definiert die kanonischen Befehle, die sowohl lokal als auch in CI verwendet werden:

```bash
just run        # flutter run --dart-define=USE_MOCK=true
just phone      # flutter run --dart-define=USE_MOCK=false
just test       # flutter test (aus app/)
just analyze    # flutter analyze (aus app/)
just gen        # flutter gen-l10n (aus app/)
just build-apk  # flutter build apk --release
just docs       # npm run dev (aus docs/)
```

Führe `just --list` aus, um alle verfügbaren Rezepte anzuzeigen.

## IDE-Empfehlungen

### VS Code

Installiere die folgenden Erweiterungen:

| Erweiterung | Herausgeber | Zweck |
|---|---|---|
| Flutter | Dart Code | Dart/Flutter-Sprachunterstützung, Debugging |
| Dart | Dart Code | Dart Language Server |
| PlatformIO IDE | PlatformIO | Firmware-Build, Upload, serieller Monitor |
| Wokwi Simulator | Wokwi | Hardware-Simulation ohne physischen ESP32 |
| Even Better TOML | tamasfe | `platformio.ini` Syntax-Highlighting |
| Prettier | Prettier | Docs/MDX-Formatierung |

Das Verzeichnis `.vscode/` im Repository enthält empfohlene Workspace-Einstellungen und Launch-Konfigurationen sowohl für die Flutter-App (mit `USE_MOCK=true`) als auch für die PlatformIO-Firmware-Projekte.

### Android Studio / IntelliJ

Die Flutter- und Dart-Plugins funktionieren gut für die App-Entwicklung. PlatformIO-Firmware entwickelst du besser in VS Code — Android Studio hat keine PlatformIO-Unterstützung.
