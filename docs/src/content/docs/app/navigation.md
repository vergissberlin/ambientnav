---
title: Navigation
description: How to use turn-by-turn navigation with the AmbientNav app.
---

The AmbientNav app provides real-time, turn-by-turn navigation with voice guidance and synchronized LED feedback on the front strip. This page explains everything from opening the map to stopping a route.

---

## Opening the App and the Map Screen

When you launch AmbientNav, the map screen is the default view. The map is powered by MapLibre and loads vector tiles from the configured tile server.

- Your current GPS position is shown as a blue dot with a heading cone.
- If the app does not yet have location permission, a banner appears at the top of the screen. Tap it to grant permission in Settings.
- If a controller is already paired and nearby, the BLE connection indicator in the top-right corner shows green. Navigation commands are sent to the LED strip automatically once a route is active.

:::note
The map screen requires location permission set to **"While Using the App"** or **"Always"**. Without it the app cannot calculate a route from your current position.
:::

---

## Searching for a Destination

1. Tap the **search bar** at the top of the map screen.
2. Begin typing a street address, place name, or point of interest.
3. The app queries the geocoder and displays a ranked list of results below the search bar.
4. Tap a result to preview it on the map — a pin drops on the selected location and a summary card slides up from the bottom.
5. Review the address shown in the summary card, then tap **Navigate** to calculate a route.

:::note
Geocoding requires an internet connection. If the device is offline, only previously cached searches are available. In offline-routing mode the route is still calculated locally — see [Online vs. Offline Mode](#online-vs-offline-mode) below.
:::

---

## Starting Navigation

### Online vs. Offline Mode

| Mode | Route engine | Requirements |
|---|---|---|
| **Online** | Valhalla (cloud-hosted) | Active internet connection |
| **Offline** | OSRM (on-device tile pack) | Offline map pack installed for your region |

The app automatically selects the appropriate engine based on network availability. You can also force a mode in **Settings → Routing**.

To start navigation:

1. With a destination selected and the summary card visible, tap **Navigate**.
2. The app calculates the route (usually under two seconds for online mode; OSRM is similarly fast once tiles are loaded).
3. The map animates to follow your vehicle heading. The route line appears on the map in blue.
4. The turn panel appears at the top of the screen.
5. The front LED strip transitions from the ambient idle effect to the first navigation effect.

---

## Understanding the Turn-by-Turn Panel

The turn panel is displayed at the top of the map screen throughout a navigation session.

| Panel element | What it shows |
|---|---|
| **Maneuver icon** | Arrow graphic for the next turn (left, right, straight, U-turn, etc.) |
| **Distance** | Remaining distance to the next maneuver (e.g., "180 m") |
| **Street name** | Name of the street onto which you are about to turn |
| **ETA bar** (bottom) | Total remaining distance and estimated arrival time |

The panel updates in real time as you move along the route. When a maneuver is less than **200 m** away, the front LED strip begins its directional sweep effect (see below).

---

## How the Front LED Strip Reacts to Navigation

The front strip reflects every maneuver instruction directly in your peripheral field of vision.

| Maneuver | LED effect |
|---|---|
| Turn left within 200 m | Amber dot sweeps from center toward the left edge |
| Turn right within 200 m | Amber dot sweeps from center toward the right edge |
| Continue straight within 200 m | White pulse grows and fades at the strip center |
| Left indicator active | Left half of the strip blinks amber |
| Right indicator active | Right half of the strip blinks amber |
| Hazard lights active | Full strip blinks amber |
| No active maneuver | Slow ambient breathing (configurable color and brightness) |

The LED state is updated every time the navigation engine emits a new instruction. There is no noticeable delay between the turn panel updating and the LED changing.

For a detailed explanation of every effect and the underlying BLE packet format, see [Front Navigation LED Strip](/modules/front-led-strip/).

---

## Voice Guidance (TTS)

AmbientNav uses the device's built-in text-to-speech engine (`flutter_tts`) to announce upcoming maneuvers.

### Announcement triggers

| Distance to maneuver | Announcement |
|---|---|
| ~500 m | "In 500 metres, turn left onto Main Street" |
| ~200 m | "In 200 metres, turn left" |
| At the maneuver | "Turn left now" |

### Adjusting voice guidance

- **Volume** — controlled by your phone's media volume.
- **Language** — the TTS engine uses the system language automatically. To use a different language, change the language in **Settings → Voice** within the app.
- **Disable voice** — toggle **Voice Guidance** off in **Settings → Voice** to use the LED strip as your only guidance cue.

:::note
Voice guidance plays through the phone speaker by default. Connect your phone to your car's Bluetooth audio system or plug in via the aux port for louder, clearer announcements while driving.
:::

### Supported languages

Any language installed on your device as a TTS voice is supported. Common options include English (US, UK, AU), German, French, Spanish, Italian, and Dutch. Install additional voices in your phone's accessibility or language settings.

---

## How to Stop Navigation

To end a navigation session at any time:

1. Tap the **stop icon** (square) in the bottom-right corner of the map screen, or
2. Swipe up on the turn panel and tap **End Route** in the sheet that appears.

After stopping:

- The route line disappears from the map.
- The turn panel is dismissed.
- The front LED strip returns to the ambient idle effect within one second.
- Voice guidance is silenced immediately.

The app does **not** automatically stop navigation when you arrive — it announces arrival and remains on the arrived screen until you dismiss it. This lets you check the final destination on the map before the strip returns to ambient mode.

---

## Tips for the Best Experience

| Tip | Reason |
|---|---|
| Keep the screen on (use the Keep Screen Awake toggle in Settings) | The app pauses LED updates and route tracking when the screen locks on some devices |
| Mount the phone at eye level or on the dashboard | Easier to glance at the turn panel; reduces neck movement |
| Connect to car audio before starting navigation | You will hear voice guidance clearly over engine and road noise |
| Download an offline map pack before long trips | Ensures navigation works in tunnels, parking garages, or areas without signal |
| Start navigation from home, not the car park | The route is calculated before you move; saves time fumbling with the phone |

:::note
The app will ask for "Always" location permission if you enable background route tracking. This is optional — "While Using the App" is sufficient for most in-car use where the screen stays on.
:::
