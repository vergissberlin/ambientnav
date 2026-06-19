# AmbientNav — Design System

> **Follow the light.** · „Folge dem Licht."

AmbientNav turns addressable LED strips into a real-time **navigation guide** and **proximity-warning** system for vehicles, inspired by VW ID.3 ambient lighting. The product is built from two **ESP32** microcontrollers (one driving navigation light, one driving proximity sensing/warning) and a custom **iOS app** that pairs over BLE and pushes turn-by-turn + distance data to the strips (WS2812B addressable LEDs).

This design system defines the AmbientNav brand: an **independent, premium-automotive identity** — deep cockpit black, a precise cyan↔magenta signal palette, geometric type, and a logo built from points of light. It is *inspired by* ID.3 ambient lighting, never an imitation of VW's brand.

The content is **bilingual (EN primary / DE secondary)**.

---

## Index / Manifest

| Path | What |
|------|------|
| `styles.css` | Root entry — `@import`s all tokens + fonts. Consumers link this. |
| `tokens/colors.css` | Signal palette, cockpit surfaces, text, glow shadows |
| `tokens/typography.css` | Font families, scale, weights, tracking |
| `tokens/spacing.css` | 4px grid, radii, shadows, motion, layout widths |
| `tokens/fonts.css` | `@font-face` for the three webfonts |
| `assets/logos/` | Logo marks (gradient / white / dark) + horizontal lockup |
| `assets/favicon.svg` | App-icon / favicon |
| `guidelines/` | Foundation specimen cards (Colors, Type, Spacing, Brand) |
| `components/` | Reusable React primitives: Button, Badge, Card, LightStrip |
| `ui_kits/ios-app/` | iOS app recreation — onboarding, live guide, proximity, settings |
| `SKILL.md` | Agent-Skill manifest |

---

## Brand context

**Product surfaces**
- **iOS app** — pair devices, pick a destination, monitor the live light guide, tune brightness/colors, see proximity zones. The app is the only screen-based surface; everything else is *light*.
- **The light itself** — the primary "UI" is the LED strip in the car. Its behavior is a designed language, documented in *Visual Foundations → The light system*.
- **Hardware** — 2× ESP32, WS2812B strips, BLE link. Referenced in copy and iconography, not a visual surface.

**Audience** — makers, automotive-tech enthusiasts, and early-adopter drivers who want calm, ambient guidance instead of another glowing screen.

---

## CONTENT FUNDAMENTALS

**Voice** — confident, calm, precise. The product reduces cognitive load, so the language does too. Short declaratives. No hype words, no exclamation marks in body copy.

**Tagline** — *Follow the light.* Always sentence case, always a full stop. German: *Folge dem Licht.*

**Bilingual pattern** — English leads; German follows as a quieter secondary line (smaller, muted `--amb-text-4`, often italic). Never machine-literal — the German is idiomatic.

**Person** — speak to the driver as *you* / *du*. Never corporate "we".

**Casing**
- Headings: sentence case (`Real-time guidance`), not Title Case.
- Eyebrows / labels / metrics: UPPERCASE mono, wide tracking (`LIVE GUIDE · 200 M`).
- The name is always **AmbientNav** (one word, internal capital N). Never "Ambient Nav" or "ambientnav".

**Numbers & units** — mono font, thin space before unit (`200 m`, `2× ESP32`, `60 fps`). Distances in metric.

**Tone examples**
- ✅ "Ambient light points the way before the next turn."
- ✅ "Magenta fills inward as the car ahead gets closer."
- ❌ "Revolutionary AI-powered smart lighting!!" (hype, untrue, wrong voice)
- ❌ "We've built the future of driving." (corporate we, vague)

**Emoji** — never. The brand's expressive layer is colored light, not emoji.

---

## VISUAL FOUNDATIONS

**Overall vibe** — premium automotive cockpit at night. Deep near-black backgrounds, restrained colored glow, sharp geometric type. Light is the only ornament; everything else is dark and quiet.

**Color**
- Two semantic accents carry meaning: **Guide Cyan `#19E3FF`** = direction & flow; **Alert Magenta `#FF2D9C`** = proximity & warning. **Signal Violet `#7C5CFF`** is the bridge and the general brand accent.
- The **brand gradient** (`cyan → violet → magenta`) represents the full signal range — guidance through caution. Used on the logo mark, hero accents, and the demonstrative light-strip graphic. Never as a flat background wash.
- Base is layered near-black: `#06080E` cockpit → `#0B0F18` / `#0E121C` surfaces → `#151A26` hover.
- Cyan and magenta are *meaningful*, never decorative — don't paint a cyan button next to a magenta one for variety; the colors signal state.

**Type** — Space Grotesk (display/headings, geometric, tight `-0.02`–`-0.035em` tracking), IBM Plex Sans (body/UI), IBM Plex Mono (eyebrows, data, metrics, wide `0.26em` tracking, UPPERCASE). The mono/Plex pairing reads "technical instrument".

**Backgrounds** — solid cockpit black, optionally with large soft radial glows in cyan (top-left) and magenta (bottom-right) at low opacity. No photographic backgrounds, no busy patterns, no purple-haze gradients across whole sections.

**Glow, not shadow** — on dark surfaces, elevation and emphasis come from a colored *glow* in the element's own hue (`--amb-glow-cyan/violet/magenta`), never a grey drop shadow. Cards use a near-flat surface fill + 1px hairline border (`--amb-line`) and a deep ambient drop only.

**Borders** — 1px hairline `rgba(255,255,255,.08)`; strong variant `.14`. Used to separate surfaces and sections.

**Corner radii** — soft, 12–16px for cards/panels, 4–8px for chips/labels. Pill (`999px`) reserved for the light-strip graphic and toggles.

**Cards** — `--amb-surface-2` fill, hairline border, 16px radius, ambient drop shadow. No colored left-border accent stripes. Hover lifts to `--amb-surface-3` and may add a faint hue glow.

**Hover / press** — hover: lighten surface one step and/or raise glow opacity. Press: scale down ~`0.97`, glow brief and brighter. Calm `cubic-bezier(.4,0,.2,1)` easing, 140–240ms.

**Motion / the light system** — the signature motif. Cyan *flows* toward the turn direction, brightening as the maneuver nears. Magenta *fills inward* as proximity closes; solid + rapid pulse = stop. Animations are light-like: opacity + position, never bouncy. Documented as `Elements` cards.

**Transparency & blur** — used for the sticky app/nav bars (`backdrop-filter: blur(14px)` over `rgba(6,8,14,.78)`). Sparingly elsewhere.

**Layout** — 1080px content container (1280 wide variant). Generous vertical rhythm (`92–120px` section padding). 4px spacing grid.

---

## ICONOGRAPHY

- **System:** [Lucide](https://lucide.dev) (CDN) — 2px stroke, round caps/joins, outline style. It matches the precise, technical, instrument-like feel and pairs cleanly with IBM Plex. Load from `https://unpkg.com/lucide@latest`.
- Icons inherit `currentColor`; in signal contexts they take the semantic hue (cyan for navigation/direction, magenta for proximity/warning, `--amb-text` neutral otherwise).
- The **navigation arrow / chevron** is the brand's signature glyph — reuse Lucide `arrow-right`, `corner-up-right`, `navigation`, `chevron-down`.
- **No emoji. No filled/duotone icon mixing.** Keep stroke style consistent at 2px.
- The **logo mark is not an icon** — never substitute it for a UI icon, and never recolor it outside its three approved variants.

> ⚠️ **Substitution flagged:** Lucide is a CDN substitution chosen to fit the brand — the product has no proprietary icon set yet. Swap in a custom set later if desired.
