---
title: CI/CD & Releases
description: GitHub Actions workflows, release automation, and versioning for AmbientNav.
---

AmbientNav uses GitHub Actions for continuous integration and automated releases. All workflows live in `.github/workflows/`.

---

## Workflows Overview

| Workflow | File | Trigger | Purpose |
|---|---|---|---|
| Build App | `build-app.yml` | Push to `main`, PRs | Lint, test, build Flutter app |
| Build Firmware | `build-firmware.yml` | Push to `main`, PRs | Build PlatformIO firmware for front + rear |
| Deploy Docs | `deploy-docs.yml` | Push to `main` (docs/ or package.json) | Build Starlight site, publish to GitHub Pages |
| Translate Docs | `translate-docs.yml` | Manual (`workflow_dispatch`) | Auto-translate EN docs to DE |
| Release Please | `release-please.yml` | Push to `main` | Automated versioning, changelog, release assets |

---

## Build App (`build-app.yml`)

Runs on every push to `main` and on pull requests.

```
flutter pub get
flutter gen-l10n
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --release
flutter build ios --release --no-codesign
```

The app builds with `USE_MOCK=false` in CI — only tests run with the mock layer. The iOS archive is built without code-signing (suitable for artifact upload, not App Store distribution).

**Artifacts uploaded:** `app-release.apk`, iOS archive.

---

## Build Firmware (`build-firmware.yml`)

Runs on every push to `main` and on pull requests.

```bash
# Front board
cd firmware/front && pio run

# Rear board
cd firmware/rear && pio run
```

PlatformIO resolves dependencies (FastLED, NimBLE-Arduino) from its registry — no manual library installation required.

**Artifacts uploaded:** `firmware-front.bin`, `firmware-rear.bin`.

---

## Deploy Docs (`deploy-docs.yml`)

Triggers on pushes to `main` that touch `docs/**` or `package.json`.

```bash
cd docs
npm ci
npm run build
```

The built static site is deployed to **GitHub Pages** using the `actions/deploy-pages` action. The base URL is `https://vergissberlin.github.io/ambientnav/`.

### Enabling GitHub Pages (first-time setup)

Before the first deploy can succeed:

1. Go to **Settings → Pages** in the repository.
2. Set **Source** to **GitHub Actions**.
3. Save — no branch selection needed.

---

## Translate Docs (`translate-docs.yml`)

Triggered manually via **Actions → Translate Docs → Run workflow**.

The workflow uses the GitHub Models API (accessed via the built-in `GITHUB_TOKEN`) to translate English content files under `docs/src/content/docs/` to German. Translated files are written to `docs/src/content/docs/de/` and committed to a bot branch for review.

:::caution
Do **not** edit the `de/` directory by hand — manual changes will be overwritten the next time the translation workflow runs. If a German translation is incorrect, fix the English source and re-run the workflow.
:::

---

## Release Process (`release-please.yml`)

AmbientNav uses [Release Please](https://github.com/googleapis/release-please) for automated semantic versioning.

### How It Works

1. You push commits to `main` using **Conventional Commits** (`feat:`, `fix:`, etc.).
2. Release Please opens a **release PR** that bumps `package.json` version and updates `CHANGELOG.md`.
3. When the release PR is merged, Release Please creates a **GitHub Release** with:
   - A git tag (`ambientnav-vX.Y.Z`)
   - Auto-generated release notes from commit messages
   - Firmware `.bin` files and app APK attached as assets

### Versioning Rules

| Commit prefix | Version bump | Example |
|---|---|---|
| `fix:` | Patch (`0.0.x`) | `fix: correct LED off-by-one` |
| `feat:` | Minor (`0.x.0`) | `feat: add OTA progress bar` |
| `feat!:` or `BREAKING CHANGE:` | Major (`x.0.0`) | `feat!: redesign BLE protocol` |
| `docs:`, `chore:`, `refactor:` | No bump | `docs: update wiring diagram` |

### Example Commit Messages

```
feat: add sensor calibration form to controller detail screen
fix: clamp LED fill percentage to 10 % minimum at critical distance
docs: add OTA troubleshooting section
chore: upgrade FastLED to 3.9.0
refactor: extract BLE codec into separate files
test: add nav codec round-trip test for max distance
```

---

## Versioned Documentation

The Starlight docs site supports multiple versions via `starlight-versions`. A new version appears in the docs version selector when:

1. A git tag `ambientnav-vX.Y.Z` exists.
2. A corresponding content directory `docs/src/content/docs/X.Y/` exists with the frozen docs for that version.

When Release Please creates a new tag, copy the current docs content to the versioned directory if you want to preserve a snapshot:

```bash
cp -r docs/src/content/docs/{getting-started.md,architecture.md,...} \
      docs/src/content/docs/0.5/
```

The `astro.config.mjs` version-sidebar builder reads existing tags and content directories automatically.

---

## Running CI Locally

Reproduce CI checks before pushing:

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

Or use the Justfile shortcuts:

```bash
just analyze   # flutter analyze
just test      # flutter test
just prepare   # pub get + gen-l10n
```

---

## Required Repository Secrets

| Secret | Source | Purpose |
|---|---|---|
| `GITHUB_TOKEN` | Auto-provided | Release Please, GitHub Pages deploy, translation API |

No additional secrets are required for the current workflow set.
