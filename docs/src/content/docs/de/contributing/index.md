---
title: "Zum AmbientNav-Projekt beitragen"
description: "Wie du mit dem Mitwirken an AmbientNav beginnst — Überblick, Verhaltenskodex und Wegweiser durch das Projekt."
---

## Willkommen

AmbientNav ist ein Open-Hardware- und Open-Software-Projekt, das Ambiente-LED-Streifen und ein ESP32-Mikrocontroller-Paar zu einer Echtzeit-Navigations- und Einparkhilfe zusammenführt. Jeder Beitrag — ob Bugfix, neuer LED-Effekt, verbesserte Übersetzung oder ein Testfall — verbessert die Erfahrung für Fahrer, die das System im Alltag nutzen.

Diese Anleitung erklärt, wie das Projekt aufgebaut ist, wie wir zusammenarbeiten und wie du deine Änderungen schnell und sauber eingebracht bekommst.

## Was du beitragen kannst

| Bereich | Beispiele |
|---|---|
| **Flutter App** | UI-Komponenten, BLE-Codec-Verbesserungen, neue Screens, Lokalisierungsstrings |
| **ESP32 Firmware** | LED-Effekte, Sensoralgorithmen, BLE/BT Classic Protokollerweiterungen |
| **Design System** | Farb-Tokens, Typografie-Verfeinerungen, neue Komponenten-Specs |
| **Dokumentation** | Nutzungsanleitungen, Architekturerklärungen, API-Referenzen |
| **Testing** | Unit-Tests, Widget-Tests, Wokwi-Simulationsszenarien |
| **Bug-Reports** | Reproduzierbare Fehler mit Schritten, Plattform und Hardware-Version |

Kein Beitrag ist zu klein. Einen Tippfehler in den Docs zu korrigieren ist genauso willkommen wie die Implementierung eines neuen Proximity-Gradienteneffekts.

## Repository-Struktur

```
ambientnav/
├── app/                    # Flutter-Anwendung (iOS + Android)
│   ├── lib/
│   │   ├── core/           # DI, Routing, Theme, gemeinsame Utilities
│   │   └── features/       # Feature-Slices (nav, ble, parking, settings)
│   └── test/               # Unit- und Widget-Tests
├── firmware/
│   ├── front/              # ESP32 Vorderplatine: BLE-Server, Nav-LEDs, Orchestrator
│   └── rear/               # ESP32 Hinterplatine: Ultraschallsensoren, hintere LEDs, BT Classic
├── design-system/          # Brand-Tokens (Farben, Typografie, Abstände), Komponenten-Specs
│   ├── tokens/
│   └── guidelines/
├── docs/                   # Diese Starlight-Dokumentationsseite
│   └── src/content/docs/
├── wokwi/                  # Wokwi-Simulationsdiagramme für die Firmware
├── justfile                # Task-Runner-Shortcuts (just test, just run, just analyze)
└── .github/workflows/      # GitHub Actions CI/CD-Pipelines
```

## Trunk-Based Development

Wir verwenden **Trunk-Based Development** auf dem `main`-Branch:

- Arbeite direkt auf `main` für kleine, in sich geschlossene Änderungen.
- Für größere Änderungen öffne einen kurzlebigen Branch (Präfix: `feat/`, `fix/`, `docs/`) und stelle dann einen Pull Request auf `main`.
- **Halte Branches kurzlebig** — idealerweise innerhalb von ein bis zwei Tagen gemergt. Vermeide langlebige Feature-Branches; sie verursachen Merge-Konflikte und driften von `main` ab.
- Pushe häufig. Viele kleine Commits auf einem Branch sind viel einfacher zu reviewen als ein einzelner großer Commit.
- Rebase auf `main`, bevor du einen Pull Request öffnest, falls dein Branch hinterherhinkt.

:::note
Wir verwenden keine `develop`-, `release/*`- oder `hotfix/*`-Branches. Alle Arbeit fließt durch `main`. Release-Automation wird von `release-please` anhand von Commit-Nachrichten gesteuert.
:::

## Issue für größere Änderungen eröffnen

Bevor du mit umfangreicherer Arbeit beginnst — einem neuen Feature, einem architekturellen Refactoring, einer Protokolländerung — **eröffne zuerst ein GitHub Issue**. Beschreibe, was du bauen möchtest und warum. Das verhindert doppelte Arbeit und gibt Maintainern die Möglichkeit, Einschränkungen zu kommunizieren (Hardware-Kompatibilität, BLE MTU-Limits, Bundle-Größe), bevor du Zeit in eine Implementierung investierst.

Für Bugs und kleine Verbesserungen ist ein direkter Pull Request ohne vorheriges Issue in Ordnung.

## Commit-Nachrichten-Konventionen

Wir verwenden **Conventional Commits**. Der CI-Workflow `release-please` liest Commit-Nachrichten, um die nächste Versionsnummer zu bestimmen und das Changelog automatisch zu generieren.

```
<type>(<optionaler scope>): <kurze Zusammenfassung im Imperativ>

[optionaler Body]

[optionaler Footer: BREAKING CHANGE: Beschreibung]
```

### Typen

| Typ | Wann zu verwenden | Versionsauswirkung |
|---|---|---|
| `feat` | Ein neues, nutzersichtbares Feature | Minor Bump (1.x.0) |
| `fix` | Ein Bugfix | Patch Bump (1.0.x) |
| `docs` | Nur Dokumentation | Kein Release |
| `chore` | Tooling, CI, Abhängigkeitsupdates | Kein Release |
| `refactor` | Code-Änderung ohne Verhaltensänderung | Kein Release |
| `test` | Tests hinzufügen oder korrigieren | Kein Release |
| `perf` | Performance-Verbesserung | Patch Bump |

### Beispiele

```
feat(parking): add proximity gradient fade for rear LEDs

The rear LED strip now fades from green to red as the vehicle
approaches an obstacle, replacing the previous solid-color alert.

fix(ble): handle MTU negotiation failure gracefully on Android 12

docs(firmware): document FreeRTOS task priorities in firmware.md

chore(deps): bump flutter to 3.27.4

feat!: change BLE GATT service UUID to follow FIDO naming convention

BREAKING CHANGE: paired devices must be re-paired after this update
because the service UUID has changed.
```

:::caution
Ein Commit mit `feat!:` oder einem `BREAKING CHANGE:`-Footer im Body löst einen **Major-Version-Bump** aus. Verwende diese nur, wenn die Änderung die Kompatibilität mit bestehender gepairter Hardware oder gespeicherten Daten bricht.
:::

## Bereiche des Mitwirkens

Wenn du die Grundlagen verstanden hast, lies den Abschnitt, der zu deinem Arbeitsbereich passt:

- **[Entwicklungsumgebung](/de/contributing/environment/)** — Tool-Versionen, Klonen, erster Start
- **[Flutter App](/de/contributing/flutter-app/)** — Architektur, Riverpod, Atomic Design, BLE-Layer
- **[Firmware](/de/contributing/firmware/)** — PlatformIO, FreeRTOS-Tasks, LED-Effekte, BLE/BT Classic
- **[Design System](/de/contributing/design-system/)** — Tokens, Brand-Guidelines, Komponenten-Konventionen
- **[Testing](/de/contributing/testing/)** — Tests ausführen, MockControllerRepository, Wokwi
- **[CI/CD & Releases](/de/contributing/ci-cd/)** — GitHub Actions Workflows, release-please, Versionierung
