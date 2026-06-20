---
title: "CI/CD & Releases"
description: "GitHub Actions workflows, release automation, and versioning for AmbientNav."
---

## Workflows Overview

All five GitHub Actions workflows live in `.github/workflows/`. They are triggered automatically — no manual intervention is required for normal development.

| Workflow file | Trigger | Purpose |
|---|---|---|
| `build-app.yml` | Push to `main`, all PRs | `flutter analyze` + `flutter test` + build APK + iOS archive (no-codesign) |
| `build-firmware.yml` | Push to `main`, all PRs | PlatformIO build for front board + rear board, upload `.bin` artifacts |
| `deploy-docs.yml` | Push to `main` touching `docs/**` or `package.json` | Astro/Starlight build + deploy to GitHub Pages |
| `translate-docs.yml` | Push to `main` touching `docs/src/content/docs/en/` | AI translation step → commit translated DE docs to bot branch for review |
| `release-please.yml` | Push to `main` | Parse Conventional Commits → create/update release PR → on merge: bump version, tag, create GitHub release with firmware `.bin` + APK artifacts |

:::tip
The fastest way to run the same checks that CI runs before pushing your changes is the `just` task runner:

```bash
just test      # flutter test
just analyze   # flutter analyze
cd docs && npm run build
```

These three commands reproduce the critical CI gates locally without waiting for GitHub Actions.
:::

## Versioning with Conventional Commits

`release-please` reads your commit messages to determine the next version number and generate the changelog. It follows [Semantic Versioning](https://semver.org/).

| Commit type | Example | Version impact |
|---|---|---|
| `fix:` | `fix(ble): handle MTU negotiation failure on Android 12` | Patch bump (1.0.**x**) |
| `feat:` | `feat(parking): add proximity gradient fade for rear LEDs` | Minor bump (1.**x**.0) |
| `feat!:` or body contains `BREAKING CHANGE:` | `feat!: change GATT service UUID` | Major bump (**x**.0.0) |
| `docs:`, `chore:`, `refactor:`, `test:` | `chore(deps): bump Flutter to 3.27.4` | No release triggered |

### Commit examples

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

## Release Walkthrough

A typical release cycle looks like this:

1. **Developer merges a `feat:` commit to `main`.**

2. **`release-please.yml` opens a release PR** titled `chore(release): v1.2.0`. The PR contains:
   - Updated version string in `pubspec.yaml` and `package.json`
   - Updated `CHANGELOG.md` with grouped commit summaries

3. **Team reviews the release PR.** Check the changelog entries are accurate and the version bump is correct. No code review needed — the PR contains only auto-generated version files.

4. **Team merges the release PR.** `release-please` then:
   - Creates the git tag `ambientnav-v1.2.0`
   - Creates a GitHub Release with auto-generated release notes
   - Triggers `build-app.yml` and `build-firmware.yml` to build the tagged commit
   - Attaches the resulting `firmware-front.bin`, `firmware-rear.bin`, and `app-release.apk` to the GitHub Release as downloadable assets

## Versioned Documentation

After a release tag is created, a new version slug becomes available in the Starlight version selector. To publish frozen docs for a release:

1. Create a versioned content subdirectory:

   ```bash
   mkdir -p docs/src/content/docs/1.2/
   # Copy the current docs you want to freeze
   cp docs/src/content/docs/getting-started.md docs/src/content/docs/1.2/
   ```

2. Push to `main`. The `deploy-docs.yml` workflow picks up the new directory and rebuilds the site.

The `astro.config.mjs` sidebar builder enumerates existing content directories automatically. No manual sidebar entry is needed for versioned content.

## Required Secrets

| Secret | Provided by | Purpose |
|---|---|---|
| `GITHUB_TOKEN` | GitHub Actions automatically | Release Please, GitHub Pages deploy, translate-docs commit |

No additional secrets need to be configured. The current workflow set operates entirely within permissions granted to `GITHUB_TOKEN` with standard repository scope.

:::note
`build-firmware.yml` does **not** flash physical hardware. It only validates that the firmware compiles successfully with PlatformIO and uploads the resulting `.bin` files as GitHub Actions artifacts. Flashing to real hardware is a manual step documented in [Firmware Development](/contributing/firmware/).
:::

## Enabling GitHub Pages for a Fork

If you fork the repository, GitHub Pages is not enabled by default. To activate it:

1. Go to **Settings → Pages** in your fork.
2. Under **Source**, select **GitHub Actions** (not a branch).
3. Save. The next push to `main` that touches `docs/` will trigger the `deploy-docs.yml` workflow and publish the site.

## Running CI Checks Locally Before Pushing

Reproduce the full CI gate locally to catch issues before they block a PR:

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

Or using the `just` shortcuts from the repository root:

```bash
just analyze
just test
cd docs && npm run build
```
