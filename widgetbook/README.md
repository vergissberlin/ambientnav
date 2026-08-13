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

| Folder | Contents |
|---|---|
| **Foundations** | Colours, typography, spacing, radius and motion specimens — ports of `design-system/guidelines/*.html`, built from the token classes so they double as verification that the Dart mirror is intact |
| **Atoms** | The brand primitives from `packages/ambientnav_ui/` — `AnButton`, `AnBadge`, `AnCard`, `AnLightStrip` |
| **App** | The app's own presentation widgets |

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

Use cases that need Riverpod providers must supply their own `ProviderScope`
with `localStoreProvider` overridden — it throws `UnimplementedError`
otherwise. `app/test/widget/pump_app.dart` is the reference wiring.

## Theme switching

Four themes are listed: the two brand themes from `AnAppTheme`, and the two
currently shipped amber themes from `AppTheme`. That is deliberate — it lets
the palette migration be reviewed side by side before it lands in the app.
