---
title: CI/CD & Releases
description: GitHub Actions Workflows, Release-Automation und Versionierung für AmbientNav.
---

AmbientNav verwendet GitHub Actions für Continuous Integration und automatisierte Releases. Alle Workflows befinden sich in `.github/workflows/`.

---

## Workflow-Überblick

| Workflow | Datei | Auslöser | Zweck |
|---|---|---|---|
| Build App | `build-app.yml` | Push auf `main`, PRs | Lint, Test, Flutter-App bauen |
| Build Firmware | `build-firmware.yml` | Push auf `main`, PRs | PlatformIO-Firmware für Vorder- und Hinterplatine bauen |
| Deploy Docs | `deploy-docs.yml` | Push auf `main` (docs/ oder package.json) | Starlight-Site bauen, auf GitHub Pages veröffentlichen |
| Translate Docs | `translate-docs.yml` | Manuell (`workflow_dispatch`) | EN-Docs automatisch nach DE übersetzen |
| Release Please | `release-please.yml` | Push auf `main` | Automatisierte Versionierung, Changelog, Release-Assets |

---

## App bauen (`build-app.yml`)

Läuft bei jedem Push auf `main` und bei Pull Requests.

```
flutter pub get
flutter gen-l10n
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --release
flutter build ios --release --no-codesign
```

Die App wird in CI mit `USE_MOCK=false` gebaut — nur Tests laufen mit dem Mock-Layer. Das iOS-Archive wird ohne Code-Signing gebaut (geeignet für Artifact-Upload, nicht für App-Store-Distribution).

**Hochgeladene Artifacts:** `app-release.apk`, iOS-Archive.

---

## Firmware bauen (`build-firmware.yml`)

Läuft bei jedem Push auf `main` und bei Pull Requests.

```bash
# Vorderplatine
cd firmware/front && pio run

# Hinterplatine
cd firmware/rear && pio run
```

PlatformIO löst Abhängigkeiten (FastLED, NimBLE-Arduino) aus seiner Registry auf — keine manuelle Bibliotheksinstallation erforderlich.

**Hochgeladene Artifacts:** `firmware-front.bin`, `firmware-rear.bin`.

---

## Docs bereitstellen (`deploy-docs.yml`)

Wird bei Pushes auf `main` ausgelöst, die `docs/**` oder `package.json` berühren.

```bash
cd docs
npm ci
npm run build
```

Die gebaute statische Site wird mit der Aktion `actions/deploy-pages` auf **GitHub Pages** deployed. Die Basis-URL ist `https://vergissberlin.github.io/ambientnav/`.

### GitHub Pages aktivieren (Ersteinrichtung)

Bevor der erste Deploy erfolgreich sein kann:

1. Gehe im Repository zu **Settings → Pages**.
2. Setze **Source** auf **GitHub Actions**.
3. Speichern — keine Branch-Auswahl erforderlich.

---

## Docs übersetzen (`translate-docs.yml`)

Wird manuell über **Actions → Translate Docs → Run workflow** ausgelöst.

Der Workflow verwendet die GitHub Models API (zugänglich über das eingebaute `GITHUB_TOKEN`), um englische Content-Dateien unter `docs/src/content/docs/` ins Deutsche zu übersetzen. Übersetzte Dateien werden in `docs/src/content/docs/de/` geschrieben und in einem Bot-Branch zum Review committed.

:::caution
Bearbeite das Verzeichnis `de/` **nicht manuell** — manuelle Änderungen werden beim nächsten Lauf des Übersetzungsworkflows überschrieben. Wenn eine deutsche Übersetzung fehlerhaft ist, korrigiere die englische Quelle und führe den Workflow erneut aus.
:::

---

## Release-Prozess (`release-please.yml`)

AmbientNav verwendet [Release Please](https://github.com/googleapis/release-please) für automatisierte semantische Versionierung.

### Wie es funktioniert

1. Du pushst Commits auf `main` mit **Conventional Commits** (`feat:`, `fix:`, etc.).
2. Release Please öffnet einen **Release-PR**, der die Version in `package.json` erhöht und `CHANGELOG.md` aktualisiert.
3. Wenn der Release-PR gemergt wird, erstellt Release Please ein **GitHub Release** mit:
   - Einem Git-Tag (`ambientnav-vX.Y.Z`)
   - Automatisch generierten Release Notes aus Commit-Nachrichten
   - Firmware-`.bin`-Dateien und App-APK als angehängte Assets

### Versionierungsregeln

| Commit-Präfix | Version-Bump | Beispiel |
|---|---|---|
| `fix:` | Patch (`0.0.x`) | `fix: correct LED off-by-one` |
| `feat:` | Minor (`0.x.0`) | `feat: add OTA progress bar` |
| `feat!:` oder `BREAKING CHANGE:` | Major (`x.0.0`) | `feat!: redesign BLE protocol` |
| `docs:`, `chore:`, `refactor:` | Kein Bump | `docs: update wiring diagram` |

### Beispiel-Commit-Nachrichten

```
feat: add sensor calibration form to controller detail screen
fix: clamp LED fill percentage to 10 % minimum at critical distance
docs: add OTA troubleshooting section
chore: upgrade FastLED to 3.9.0
refactor: extract BLE codec into separate files
test: add nav codec round-trip test for max distance
```

---

## Versionierte Dokumentation

Die Starlight-Docs-Site unterstützt mehrere Versionen über `starlight-versions`. Eine neue Version erscheint im Docs-Versionsauswahlmenü, wenn:

1. Ein Git-Tag `ambientnav-vX.Y.Z` existiert.
2. Ein entsprechendes Content-Verzeichnis `docs/src/content/docs/X.Y/` mit den eingefrorenen Docs für diese Version existiert.

Wenn Release Please einen neuen Tag erstellt, kopiere den aktuellen Docs-Inhalt in das versionierte Verzeichnis, wenn du einen Snapshot erhalten möchtest:

```bash
cp -r docs/src/content/docs/{getting-started.md,architecture.md,...} \
      docs/src/content/docs/0.5/
```

Der `astro.config.mjs`-Versions-Sidebar-Builder liest vorhandene Tags und Content-Verzeichnisse automatisch aus.

---

## CI lokal ausführen

CI-Checks vor dem Push reproduzieren:

```bash
# App
cd app
flutter pub get && flutter gen-l10n
dart format --set-exit-if-changed .
flutter analyze
flutter test

# Firmware
cd firmware/front && pio run
cd firmware/rear && pio run

# Docs
cd docs && npm ci && npm run build
```

Oder die Justfile-Shortcuts verwenden:

```bash
just analyze   # flutter analyze
just test      # flutter test
just prepare   # pub get + gen-l10n
```

---

## Erforderliche Repository-Secrets

| Secret | Quelle | Zweck |
|---|---|---|
| `GITHUB_TOKEN` | Automatisch bereitgestellt | Release Please, GitHub Pages Deploy, Übersetzungs-API |

Für den aktuellen Workflow-Satz sind keine weiteren Secrets erforderlich.
