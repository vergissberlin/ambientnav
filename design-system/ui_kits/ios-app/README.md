# AmbientNav — iOS App UI Kit

High-fidelity recreation of the AmbientNav companion app. The app is the only screen-based surface of the product — everything else is *light*.

`index.html` is the interactive composition: two device frames (Live Guide + Parking Assist) with a working bottom tab bar. Tap the tabs to move between the four core screens.

## Screens

| Screen | Purpose |
|--------|---------|
| **Live Guide** | Active turn-by-turn. Next maneuver card, a perspective preview of the dashboard LED strip (cyan flowing toward the turn), speed + strip refresh metrics. |
| **Parking Assist** | Rear proximity. Large live distance read-out, zone label (Clear / Close / Stop), magenta strip filling inward; a slider simulates closing distance. |
| **Devices** | BLE pairing for the two ESP32 controllers (Front = navigation light, Rear = proximity sensor) and link status + hardware tags. |
| **Settings** | Brightness, auto-dim, proximity-warning toggle, guide-color swatches. |

## Build notes

- Self-contained: React 18 + Babel via CDN. JSX is transformed with the **classic** runtime via a manual `Babel.transform` runner (the environment's auto-runner defaults to the automatic runtime, which injects `import` statements that fail when executed as a non-module script).
- The LED `Strip` component is reimplemented inline here for portability; the canonical version is `components/light/LightStrip.jsx`.
- Icons are Lucide-style 2px-stroke inline SVGs, matching the iconography guideline.
- All color/type/spacing pull from `../../styles.css` design tokens.

## Source of truth

This is a brand recreation built from the AmbientNav design system (no prior production app existed). Treat screen content as representative, not final product copy.
