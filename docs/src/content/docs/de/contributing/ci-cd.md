---
title: "CI/CD & Releases"
description: "GitHub Actions Workflows, Release-Automatisierung und Versionierung für AmbientNav."
---

## Übersicht der Workflows

Alle fünf GitHub Actions Workflows liegen in `.github/workflows/`. Sie werden automatisch ausgelöst — für die normale Entwicklung ist kein manueller Eingriff erforderlich.

| Workflow-Datei | Auslöser | Zweck |
|---|---|---|
| `build-app.yml` | Push auf `main`, alle PRs | `flutter analyze` + `flutter test` + APK bauen + iOS-Archiv (no-codesign) |
| `build-firmware.yml` | Push auf `main`, alle PRs | PlatformIO-Build für Front- und Rear-Board, `.bin`-Artefakte hochladen |
| `deploy-docs.yml` | Push auf `main`, der `docs/**` oder `package.json` berührt | Astro/Starlight-Build + Deploy auf GitHub Pages |
| `translate-docs.yml` | Push auf `main`, der `docs/src/content/docs/en/` berührt | KI-Übersetzungsschritt → übersetzte DE-Docs in Bot-Branch für Review committen |
| `release-please.yml` | Push auf `main` | Conventional Commits parsen → Release-PR erstellen/aktualisieren → bei Merge: Version hochzählen, Tag setzen, GitHub Release mit Firmware-`.bin` + APK-Artefakten erstellen |

:::tip
Der schnellste Weg, dieselben Prüfungen wie CI lokal durchzuführen, bevor du Änderungen pushst, ist der `just`-Task-Runner:

```bash
just test      # flutter test
just analyze   # flutter analyze
cd docs && npm run build
```

Diese drei Befehle reproduzieren die kritischen CI-Gates lokal, ohne auf GitHub Actions warten zu müssen.
:::

## Versionierung mit Conventional Commits

`release-please` liest deine Commit-Nachrichten, um die nächste Versionsnummer zu bestimmen und das Changelog zu generieren. Es folgt [Semantic Versioning](https://semver.org/).

| Commit-Typ | Beispiel | Auswirkung auf Version |
|---|---|---|
| `fix:` | `fix(ble): handle MTU negotiation failure on Android 12` | Patch-Bump (1.0.**x**) |
| `feat:` | `feat(parking): add proximity gradient fade for rear LEDs` | Minor-Bump (1.**x**.0) |
| `feat!:` oder Body enthält `BREAKING CHANGE:` | `feat!: change GATT service UUID` | Major-Bump (**x**.0.0) |
| `docs:`, `chore:`, `refactor:`, `test:` | `chore(deps): bump Flutter to 3.27.4` | Kein Release ausgelöst |

### Commit-Beispiele

```
# Triggers a patch release (1.0.3 → 1.0.4)
fix(nav): clamp bearing value to 0–360 range before LED encoding

# Triggers a minor release (1.0.4 → 1.1.0)
feat(settings): add per-channel LED brightness controls

# Triggers a major release (1.1.0 → 2.0.0)
feat!: redesign BLE GATT protocol to use 16-bit UUIDs

BREAKING CHANGE: All previously paired devices must be re-paired.
The GATT service UUID has changed from 180D to FFA0.

# No release triggered
chore: upgrade NimBLE-Arduino to 1.4.2
```

## Release-Ablauf

Ein typischer Release-Zyklus sieht so aus:

1. **Ein Entwickler mergt einen `feat:`-Commit auf `main`.**

2. **`release-please.yml` öffnet einen Release-PR** mit dem Titel `chore(release): v1.2.0`. Der PR enthält:
   - Aktualisierten Versionsstring in `pubspec.yaml` und `package.json`
   - Aktualisierte `CHANGELOG.md` mit gruppierten Commit-Zusammenfassungen

3. **Das Team überprüft den Release-PR.** Prüfe, ob die Changelog-Einträge korrekt und der Versions-Bump stimmig sind. Kein Code-Review nötig — der PR enthält nur automatisch generierte Versionsdateien.

4. **Das Team mergt den Release-PR.** `release-please` führt dann folgendes aus:
   - Erstellt den Git-Tag `ambientnav-v1.2.0`
   - Erstellt ein GitHub Release mit automatisch generierten Release Notes
   - Löst `build-app.yml` und `build-firmware.yml` aus, um den getaggten Commit zu bauen
   - Fügt die resultierenden `firmware-front.bin`, `firmware-rear.bin` und `app-release.apk` als herunterladbare Assets an das GitHub Release an

## Versionierte Dokumentation

Nach der Erstellung eines Release-Tags wird im Starlight-Versionselektor ein neuer Versions-Slug verfügbar. So veröffentlichst du eingefrorene Docs für einen Release:

1. Erstelle ein versioniertes Inhaltsunterverzeichnis:

   ```bash
   mkdir -p docs/src/content/docs/1.2/
   # Copy the current docs you want to freeze
   cp docs/src/content/docs/getting-started.md docs/src/content/docs/1.2/
   ```

2. Push auf `main`. Der `deploy-docs.yml`-Workflow erkennt das neue Verzeichnis und baut die Seite neu.

Der Sidebar-Builder in `astro.config.mjs` enumeriert vorhandene Inhaltsverzeichnisse automatisch. Für versionierte Inhalte ist kein manueller Sidebar-Eintrag erforderlich.

## Benötigte Secrets

| Secret | Bereitgestellt von | Zweck |
|---|---|---|
| `GITHUB_TOKEN` | GitHub Actions automatisch | release-please, GitHub Pages Deploy, translate-docs-Commit |

Es müssen keine weiteren Secrets konfiguriert werden. Das aktuelle Workflow-Set arbeitet vollständig innerhalb der Berechtigungen, die `GITHUB_TOKEN` mit Standard-Repository-Scope gewährt werden.

:::note
`build-firmware.yml` flasht **keine** physische Hardware. Es überprüft lediglich, dass die Firmware mit PlatformIO erfolgreich kompiliert, und lädt die resultierenden `.bin`-Dateien als GitHub Actions Artefakte hoch. Das Flashen auf echte Hardware ist ein manueller Schritt, der unter [Firmware-Entwicklung](/contributing/firmware/) dokumentiert ist.
:::

## GitHub Pages für einen Fork aktivieren

Wenn du das Repository forkst, ist GitHub Pages standardmäßig nicht aktiviert. So schaltest du es frei:

1. Gehe in deinem Fork zu **Settings → Pages**.
2. Wähle unter **Source** die Option **GitHub Actions** (nicht einen Branch).
3. Speichern. Beim nächsten Push auf `main`, der `docs/` berührt, wird der `deploy-docs.yml`-Workflow ausgelöst und die Seite veröffentlicht.

## CI-Prüfungen lokal vor dem Push ausführen

Reproduziere das vollständige CI-Gate lokal, um Probleme zu finden, bevor sie einen PR blockieren:

```bash
# 1. App analysis and tests
cd app
flutter pub get
flutter gen-l10n
flutter analyze
flutter test

# 2. Firmware build (validates both boards compile)
cd ../firmware/front && pio run
cd ../firmware/rear && pio run

# 3. Docs build (catches broken links and MDX syntax errors)
cd ../../docs && npm install && npm run build
```

Oder mit den `just`-Kürzeln vom Repository-Wurzelverzeichnis:

```bash
just analyze
just test
cd docs && npm run build
```
