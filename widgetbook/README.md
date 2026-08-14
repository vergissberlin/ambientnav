# AmbientNav — Widgetbook

Component catalogue for the AmbientNav Flutter UI. Renders every catalogued
widget in isolation, across themes, locales, viewports and text scales.

```bash
just widgetbook            # run in Chrome
just widgetbook macos      # or another device
just widgetbook-test       # pump every use case
just widgetbook-build      # static web build
```

## What is in here

Grouped by **atomic tier, not by package** — the brand primitives and the app's
own widgets sit together, because that is how someone looking for a component
thinks about it.

| Folder | Contents |
|---|---|
| **Foundations** | Colour, typography, spacing, radius and motion specimens — ports of `design-system/guidelines/*.html`, built from the token classes so they double as verification that the Dart mirror is intact |
| **Atoms** | `AnButton`, `AnBadge`, `AnCard`, `AnLightStrip` from `ambientnav_ui`, plus `BatteryGauge` and `RssiIndicator` |
| **Molecules** | `ControllerTile`, `PairingBanner`, `OtaProgressView`, `TurnByTurnPanel` |
| **Organisms** | `ControllerTelemetryList`, and the provider-bound `LedConfigForm`, `SensorCalibrationForm`, `PairingDialog` |
| **Screens** | `SettingsScreen`, `ControllersListScreen`, `SearchScreen` — catalogued in place, never moved |

There is no Templates or Pages tier. The one Templates candidate (`HomeShell`)
is a fixed three-tab `IndexedStack` with no content slots, and Pages in the
original model is exactly what `features/**/presentation/` already is.

`MapScreen` and `OtaScreen` are excluded: the first embeds a native platform
view that will not render on web, the second reaches `FilePicker.platform`
statically. `OtaScreen`'s progress section was extracted as `OtaProgressView`
precisely so its six states stay reviewable.

## Why a separate package

The catalogue depends on the app, not the other way round. Keeping it out of
`app/` means Widgetbook and its transitive dependencies never enter the shipped
app's lock file, and — more importantly — a broken use case can only fail this
package's workflow. `build-app.yml` gates the release; the catalogue must never
be able to block it.

`ambientnav_ui` carries no dependency on the app at all: it is
localisation-free and app-agnostic, which is what avoids a dependency cycle,
since `AppLocalizations` lives in `package:ambientnav`.

## Adding a use case

The directory tree in `lib/directories.dart` is hand-written — see the comment
there for why, and for the conditions under which switching to
`widgetbook_generator` would be worth it.

1. Add a `WidgetbookUseCase` to the relevant file under `lib/use_cases/`.
2. Register it in a `WidgetbookComponent` inside that file's folder function.
3. `just widgetbook-test` — every registered use case is pumped, so a broken
   builder fails there rather than being found by someone scrolling the UI.

`test/component_coverage_test.dart` additionally fails when a component in
`app/lib/ui` or `packages/ambientnav_ui/lib/atoms` has no use case at all.
Genuine exceptions go in `kUseCaseExempt` with a reason.

### Provider-bound use cases

`lib/support/` has the two wrappers:

- **`UseCaseScope`** — a `ProviderScope` with `localStoreProvider` overridden.
  Mandatory for anything touching theme or dev settings, since that provider
  throws `UnimplementedError` otherwise. Mirrors `app/test/widget/pump_app.dart`
  so a use case and a widget test exercise the same graph.
- **`MockRepoScope`** — a `MockControllerRepository` already connected and
  optionally paired. Pass `paired: false` to see the `NotPairedException` path,
  which otherwise needs an unpaired physical controller.

`SearchScreen` uses `FixtureGeocodingService`. That is required, not
convenience: the real service queries Nominatim on every keystroke, and its
usage policy forbids automated querying.

## Theme switching

Four themes are listed: the two brand themes from `AnAppTheme`, and the two
currently shipped amber themes from `AppTheme`. That is deliberate — it lets
the palette migration be reviewed side by side before it lands in the app.
