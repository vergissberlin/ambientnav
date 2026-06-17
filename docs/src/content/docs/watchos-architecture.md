---
title: watchOS Architecture (Planned)
description: Documented architecture for a future Apple Watch companion to the AmbientNav app.
---

A watchOS companion is **planned, not yet implemented**. This page records the
intended architecture so it can be added later without reworking the app.

## Goal

Show the driver the **next maneuver** (icon + instruction) and the **distance to
it** on the wrist, mirroring the phone's turn-by-turn panel. The watch is a
**display/secondary control**, not the navigation engine.

## Approach

- The watchOS app is a **native SwiftUI** target (Flutter does not target
  watchOS). It is intentionally thin.
- It communicates with the iPhone app via **WatchConnectivity** (`WCSession`).
  The Flutter app exposes the same navigation snapshot used by the CarPlay /
  Android Auto heads — see `lib/features/car/car_session_state.dart` — over a
  `MethodChannel`, and forwards it to the watch as a lightweight message:

  ```jsonc
  {
    "maneuver": "turnLeft",       // ManeuverType
    "instruction": "Turn left onto Main St",
    "distanceMeters": 120,
    "isNavigating": true
  }
  ```

- The watch renders the maneuver glyph + distance and updates on each change
  (delta-driven), matching the phone's "publish on change" rule to save energy.

## Out of scope (initially)

- BLE directly from the watch to the controllers (the phone remains the BLE
  central). Controller configuration/OTA stay on the phone.
- Independent routing on the watch.

## Why this shape

- One **source of truth** (`CarSessionState`) already feeds the car heads;
  reusing it for the watch avoids divergent navigation state.
- Keeping the watch native + thin sidesteps Flutter's lack of watchOS support
  while still delivering the glanceable maneuver display users expect.
