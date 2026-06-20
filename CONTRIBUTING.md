# Contributing to AmbientNav

Welcome — and thank you for your interest in AmbientNav. This file gives you everything you need to make your first contribution. For deeper coverage of any topic, the full contributing docs live at **[vergissberlin.github.io/ambientnav](https://vergissberlin.github.io/ambientnav/)**.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [What You Can Contribute](#what-you-can-contribute)
3. [Development Setup](#development-setup)
4. [Project Structure](#project-structure)
5. [Workflow](#workflow)
6. [Testing](#testing)
7. [Code Style](#code-style)
8. [Commit Message Convention](#commit-message-convention)
9. [Pull Requests](#pull-requests)
10. [Documentation](#documentation)
11. [License](#license)

---

## Quick Start

```bash
# 1. Clone and enter the repo
git clone https://github.com/vergissberlin/ambientnav.git
cd ambientnav

# 2. Install Flutter app dependencies and regenerate localizations
cd app && flutter pub get && flutter gen-l10n && cd ..

# 3. Run the app with the in-memory mock BLE layer (no hardware required)
flutter run --dart-define=USE_MOCK=true

# Or use the shortcut via just (https://github.com/casey/just)
just prepare   # install deps + gen-l10n
just run       # boots iOS Simulator + runs with mock BLE
```

Drop `--dart-define=USE_MOCK=true` to connect to a real ESP32 over BLE on a physical device.

---

## What You Can Contribute

| Area | Examples |
|---|---|
| **Firmware** | New LED effects, sensor calibration improvements, BLE/SPP protocol changes, ESP32 power optimisations |
| **Flutter app** | UI screens, BLE features, routing/map improvements, accessibility, new platform targets |
| **Documentation** | Corrections, new guides, wiring diagrams, protocol clarifications |
| **Design system** | Design tokens, components, brand assets in `design-system/` |
| **Bug reports** | Reproducible bugs via the [bug report template](.github/ISSUE_TEMPLATE/bug.yml) |
| **Ideas** | Feature proposals and questions via [GitHub Issues](https://github.com/vergissberlin/ambientnav/issues) |

---

## Development Setup

### Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Flutter | 3.27+ (Dart 3.6+) | `flutter --version` |
| Xcode | 15+ | iOS builds only |
| Android SDK | API 36+ | Android builds |
| PlatformIO | latest | VS Code extension or `pip install platformio` |
| just | any | Optional task runner: `brew install just` / `cargo install just` |
| Node.js + pnpm | 20+ / 10+ | Docs site only |

### Flutter app

```bash
cd app
flutter pub get
flutter gen-l10n          # generates localisation delegates
flutter run --dart-define=USE_MOCK=true
```

### ESP32 firmware

```bash
# Flash the front ESP32
cd firmware/front && pio run --target upload

# Flash the rear ESP32
cd firmware/rear && pio run --target upload
```

The `wokwi/` directory contains Wokwi simulation diagrams for both units. You can run simulations in VS Code with the [Wokwi extension](https://docs.wokwi.com/vscode/getting-started) without physical hardware.

### Docs site

```bash
cd docs
pnpm install
pnpm dev     # starts Astro dev server at http://localhost:4321
```

Full setup instructions: [vergissberlin.github.io/ambientnav](https://vergissberlin.github.io/ambientnav/).

---

## Project Structure

```
ambientnav/
├── app/                        # Flutter app (iOS + Android)
│   ├── lib/
│   │   ├── core/               # DI, router, theme, l10n, persistence
│   │   └── features/
│   │       ├── navigation/     # MapLibre + Valhalla routing + voice guidance
│   │       ├── offline/        # Offline map region download
│   │       ├── controllers/    # BLE: telemetry, LED/sensor config, OTA, pairing
│   │       ├── car/            # CarPlay / Android Auto scaffolds
│   │       └── settings/       # Theme & preferences
│   └── test/                   # Unit + widget tests (mock BLE layer)
├── firmware/
│   ├── front/                  # ESP32 Master — BLE peripheral, navigation LEDs
│   │   └── src/
│   └── rear/                   # ESP32 Slave — ultrasonic sensors, parking LEDs
│       └── src/
├── design-system/              # Brand tokens, components, assets, guidelines
│   ├── tokens/                 # CSS custom properties (colors, type, spacing)
│   ├── components/             # React primitives: Button, Badge, Card, LightStrip
│   ├── assets/                 # Logos, favicon, background SVGs
│   └── guidelines/             # Specimen cards for colors, type, spacing, brand
├── docs/                       # Starlight (Astro) documentation site
│   └── src/content/docs/       # EN source; de/ is auto-translated
├── wokwi/                      # Wokwi simulation diagrams
│   ├── front/diagram.json
│   └── rear/diagram.json
├── .github/
│   ├── workflows/              # CI: build-app, build-firmware, deploy-docs, translate-docs, release-please
│   └── ISSUE_TEMPLATE/         # Bug, idea, question, docs templates
└── Justfile                    # Development shortcuts (just run, just test, …)
```

---

## Workflow

AmbientNav uses **trunk-based development**. All work lands on `main`.

- **Small, focused commits.** Each commit should do one thing and pass CI.
- **Open an issue first** for any change that touches architecture, public APIs, or the BLE/SPP protocol. For small fixes, a PR is fine without a prior issue.
- **No long-lived feature branches.** If a change takes more than a day or two, break it into smaller vertical slices.
- **CI gates.** The `build-app` workflow runs `flutter analyze`, `dart format`, and `flutter test` on every push to `main` and every PR touching `app/`. The `build-firmware` workflow runs `pio run` for both targets. All checks must pass before merge.

---

## Testing

### Flutter app

```bash
# Static analysis (runs flutter_lints)
cd app && flutter analyze

# All unit and widget tests (runs against the in-memory mock BLE layer)
cd app && flutter test

# Format check (matches CI)
cd app && dart format --set-exit-if-changed lib test

# Or via just
just analyze
just test
```

### Firmware

PlatformIO has no unit test target configured yet. The primary verification path is a build check:

```bash
cd firmware/front && pio run
cd firmware/rear  && pio run
```

For interactive simulation, use the Wokwi diagrams in `wokwi/front/` and `wokwi/rear/`.

---

## Code Style

### Flutter / Dart

- Follow [`package:flutter_lints`](https://pub.dev/packages/flutter_lints) (configured in `app/analysis_options.yaml`).
- Run `flutter analyze` and `dart format lib test` before committing. CI enforces both.
- Do not hard-code colors. Use `AppTheme` and the design tokens from `design-system/tokens/`.
- Prefer `const` constructors wherever possible.
- State management: Riverpod providers only — no `setState` outside of leaf widgets.

### C++ (ESP32 firmware)

- Follow the existing code style in `firmware/front/src/` and `firmware/rear/src/`.
- Format with `clang-format` if available; otherwise match the surrounding style.
- Do not hard-code LED colors as magic numbers. Prefer named constants or the shared `led_effects.h` palette.
- Keep ISR handlers minimal — defer work to FreeRTOS tasks.
- Document public functions with a brief comment explaining purpose and parameters.

### Documentation (Markdown / MDX)

- English is the source language. German translations in `docs/src/content/docs/de/` are generated automatically (see [Documentation](#documentation)).
- Use sentence case for headings.
- Product name is always **AmbientNav** — one word, capital N.

---

## Commit Message Convention

This project follows [Conventional Commits](https://www.conventionalcommits.org/). Commit messages are used to generate the changelog automatically via `release-please`.

```
<type>(<scope>): <short summary in imperative mood>

[optional body]

[optional footer(s)]
```

| Type | When to use | Example |
|---|---|---|
| `feat` | New feature or behaviour | `feat(app): add offline route caching` |
| `fix` | Bug fix | `fix(firmware/rear): clamp sensor distance to 0–400 cm` |
| `docs` | Documentation only | `docs: add wiring diagram for 38-pin DevKit` |
| `chore` | Tooling, deps, CI, build scripts | `chore: upgrade Flutter to 3.27.1` |
| `refactor` | Code change with no behaviour change | `refactor(app): extract BleRepository interface` |
| `test` | Add or update tests | `test(app): cover mock BLE disconnect scenario` |
| `style` | Formatting, whitespace, no logic change | `style: apply dart format to controllers/` |
| `perf` | Performance improvement | `perf(firmware/front): reduce FastLED show() call rate` |

**Breaking changes** — append `!` after the type/scope and add a `BREAKING CHANGE:` footer:

```
feat(ble)!: update GATT characteristic UUID format

BREAKING CHANGE: Clients must re-pair after flashing this firmware.
```

---

## Pull Requests

Most small fixes and improvements can be pushed directly to `main`. Open a PR when:

- The change is non-trivial and benefits from a review.
- You are an external contributor (fork-based workflow).
- The change touches the BLE/SPP protocol, the design system, or the public docs structure.

### PR checklist

- [ ] Linked to a relevant issue (if one exists).
- [ ] All CI checks pass (`flutter analyze`, `flutter test`, `pio run`).
- [ ] Commits follow the [Conventional Commits](#commit-message-convention) format.
- [ ] New behaviour is covered by tests (app) or verified in Wokwi (firmware).
- [ ] Documentation updated if the change affects user-facing behaviour.

### PR description template

```markdown
## What
Brief description of the change and motivation.

## How
Key implementation decisions.

## Testing
How you verified this works (test run, Wokwi sim, physical hardware).

## Related issues
Closes #<issue>
```

---

## Documentation

The docs site is built with [Astro Starlight](https://starlight.astro.build/) and lives in `docs/`. It is deployed to GitHub Pages at **[vergissberlin.github.io/ambientnav](https://vergissberlin.github.io/ambientnav/)** via the `deploy-docs` workflow on every push to `main` that touches `docs/`.

### Run locally

```bash
cd docs
pnpm install
pnpm dev
```

The dev server starts at `http://localhost:4321` with hot reload.

### Adding or editing content

- English source files live in `docs/src/content/docs/` (flat and versioned under `0.1/`).
- Add new pages as `.md` or `.mdx` files; Starlight picks them up automatically.
- Update the sidebar in `docs/astro.config.mjs` if you add a top-level section.

### Auto-translation (EN → DE)

German translations in `docs/src/content/docs/de/` are generated automatically by the `translate-docs` GitHub Actions workflow. It uses the GitHub Models API (no extra API key required — uses your `GITHUB_TOKEN`).

To trigger a translation run manually:

1. Go to **Actions → Translate Docs (EN → DE)** in the GitHub UI.
2. Click **Run workflow**.

Do not manually edit files under `docs/src/content/docs/de/` — manual changes will be overwritten on the next translation run. If a translation is wrong, fix the English source and retrigger the workflow.

---

## Links

- Full contributing docs: [vergissberlin.github.io/ambientnav](https://vergissberlin.github.io/ambientnav/)
- Issue templates: [.github/ISSUE_TEMPLATE/](.github/ISSUE_TEMPLATE/)
- Design system: [design-system/readme.md](design-system/readme.md)
- App architecture: [app/README.md](app/README.md)
- BLE & SPP protocol: [docs/src/content/docs/](docs/src/content/docs/)

---

## License

AmbientNav is released under the [MIT License](LICENSE). By contributing, you agree that your contributions will be licensed under the same terms.
