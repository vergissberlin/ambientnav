---
name: ambientnav-design
description: Use this skill to generate well-branded interfaces and assets for AmbientNav, either for production or throwaway prototypes/mocks/etc. Contains essential design guidelines, colors, type, fonts, assets, and UI kit components for prototyping. AmbientNav is an ambient-LED navigation + parking-assist system for vehicles (2× ESP32, WS2812B strips, iOS app), with a dark premium-automotive identity and a cyan↔magenta signal palette.
user-invocable: true
---

Read the `readme.md` file within this skill, and explore the other available files.

If creating visual artifacts (slides, mocks, throwaway prototypes, etc), copy assets out and create static HTML files for the user to view. If working on production code, you can copy assets and read the rules here to become an expert in designing with this brand.

If the user invokes this skill without any other guidance, ask them what they want to build or design, ask some questions, and act as an expert designer who outputs HTML artifacts _or_ production code, depending on the need.

Key files:
- `styles.css` — link this one file to get all tokens + fonts.
- `tokens/` — colors, typography, spacing, fonts.
- `assets/logos/` — logo marks + lockup.
- `guidelines/` — foundation specimen cards.
- `components/` — Button, Badge, Card, LightStrip (React).
- `ui_kits/ios-app/` — interactive iOS app recreation.

Core rules: dark cockpit base; cyan = direction/guidance, magenta = proximity/warning (never decorative); glow not grey shadow; Space Grotesk + IBM Plex Sans + IBM Plex Mono; bilingual EN/DE; no emoji.
