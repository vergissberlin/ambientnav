---
title: "Contributing to AmbientNav"
description: "How to get started contributing to AmbientNav — overview, code of conduct, and where to find what."
---

## Welcome

AmbientNav is an open hardware and software project that turns ambient LED strips and an ESP32 microcontroller pair into a real-time navigation and parking aid. Every contribution — whether it's a bug fix, a new LED effect, an improved translation, or a test case — directly improves the experience for drivers using the system on the road.

This guide explains how the project is structured, how we work, and how to get your changes merged quickly and cleanly.

## What You Can Contribute

| Area | Examples |
|---|---|
| **Flutter app** | UI components, BLE codec improvements, new screens, localization strings |
| **ESP32 firmware** | LED effects, sensor algorithms, BLE/BT Classic protocol extensions |
| **Design system** | Color tokens, typography refinements, new component specs |
| **Documentation** | Usage guides, architecture explanations, API references |
| **Testing** | Unit tests, widget tests, Wokwi simulation scenarios |
| **Bug reports** | Reproducible issues with steps, platform, and hardware version |

No contribution is too small. Correcting a typo in the docs is as welcome as implementing a new proximity gradient effect.

## Repository Structure

```
ambientnav/
├── app/                    # Flutter application (iOS + Android)
│   ├── lib/
│   │   ├── core/           # DI, routing, theme, shared utilities
│   │   └── features/       # Feature slices (nav, ble, parking, settings)
│   └── test/               # Unit and widget tests
├── firmware/
│   ├── front/              # ESP32 front board: BLE server, nav LEDs, orchestrator
│   └── rear/               # ESP32 rear board: ultrasonic sensors, rear LEDs, BT Classic
├── design-system/          # Brand tokens (colors, typography, spacing), component specs
│   ├── tokens/
│   └── guidelines/
├── docs/                   # This Starlight documentation site
│   └── src/content/docs/
├── wokwi/                  # Wokwi simulator diagrams for firmware
├── justfile                # Task runner shortcuts (just test, just run, just analyze)
└── .github/workflows/      # GitHub Actions CI/CD pipelines
```

## Trunk-Based Development

We use **trunk-based development** on the `main` branch:

- Work directly on `main` for small, self-contained changes.
- For larger changes, open a short-lived branch (prefix: `feat/`, `fix/`, `docs/`), then open a pull request targeting `main`.
- **Keep branches short-lived** — ideally merged within one or two days. Avoid long-lived feature branches; they create merge pain and drift from `main`.
- Push often. Frequent small commits on a branch are much easier to review than one large commit.
- Rebase on `main` before opening a pull request if your branch has fallen behind.

:::note
We do not use `develop`, `release/*`, or `hotfix/*` branches. All work flows through `main`. Release automation is handled by `release-please` based on commit messages.
:::

## Open an Issue for Larger Changes

Before starting significant work — a new feature, an architectural refactor, a protocol change — **open a GitHub issue first**. Describe what you want to build and why. This prevents duplicated effort and gives maintainers a chance to flag constraints (hardware compatibility, BLE MTU limits, bundle size) before you invest time in an implementation.

For bugs and small improvements, a direct pull request without a prior issue is fine.

## Commit Message Conventions

We use **Conventional Commits**. The CI `release-please` workflow reads commit messages to determine the next version number and generate the changelog automatically.

```
<type>(<optional scope>): <short summary in imperative mood>

[optional body]

[optional footer: BREAKING CHANGE: description]
```

### Types

| Type | When to use | Version impact |
|---|---|---|
| `feat` | A new user-visible feature | Minor bump (1.x.0) |
| `fix` | A bug fix | Patch bump (1.0.x) |
| `docs` | Documentation only | No release |
| `chore` | Tooling, CI, dependency updates | No release |
| `refactor` | Code change with no behavior change | No release |
| `test` | Adding or fixing tests | No release |
| `perf` | Performance improvement | Patch bump |

### Examples

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
A commit with `feat!:` or a `BREAKING CHANGE:` footer in the body triggers a **major version bump**. Use these only when the change breaks compatibility with existing paired hardware or stored data.
:::

## Contributing Sections

Once you have the basics down, consult the section relevant to what you're working on:

- **[Development Environment](/contributing/environment/)** — Tool versions, cloning, first run
- **[Flutter App](/contributing/flutter-app/)** — Architecture, Riverpod, Atomic Design, BLE layer
- **[Firmware](/contributing/firmware/)** — PlatformIO, FreeRTOS tasks, LED effects, BLE/BT Classic
- **[Design System](/contributing/design-system/)** — Tokens, brand guidelines, component conventions
- **[Testing](/contributing/testing/)** — Running tests, MockControllerRepository, Wokwi
- **[CI/CD & Releases](/contributing/ci-cd/)** — GitHub Actions workflows, release-please, versioning
