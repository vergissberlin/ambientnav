# CarPlay & Android Auto integration

AmbientNav shares one navigation source of truth — `carSessionStateProvider`
(`lib/features/car/car_session_state.dart`) — between the phone UI and the car
heads. `CarBridge` (`lib/features/car/car_bridge.dart`) forwards each snapshot
(next maneuver, instruction, distance) to native over the MethodChannel
`digital.thinkport.ambientnav/car`.

The Dart bridge and the native template files are in the repo, but the native
heads are **not wired into the build** so the standard `flutter build apk` /
`flutter build ios` stay green without entitlements. Enable them as follows.

## CarPlay (iOS)

1. Request the **CarPlay entitlement** from Apple
   (`com.apple.developer.carplay-maps`) and add it to `Runner.entitlements`.
2. Declare a CarPlay scene in `ios/Runner/Info.plist`
   (`UIApplicationSceneManifest` → a `CPTemplateApplicationSceneSessionRoleApplication`
   role pointing at `CarPlaySceneDelegate`).
3. The delegate is provided in `ios/Runner/CarPlaySceneDelegate.swift`
   (`CPMapTemplate` + maneuver banner driven by the MethodChannel).
4. Test in the **CarPlay Simulator** (Xcode → Open Developer Tool → Simulator →
   I/O → External Displays → CarPlay).

## Android Auto

1. Add the Jetpack Car App library to `android/app/build.gradle`:
   `implementation "androidx.car.app:app:1.4.0"` (+ `app-projected` for testing).
2. Declare the service + `automotive_app_desc.xml` in `AndroidManifest.xml`
   pointing at `AmbientNavCarAppService`.
3. Uncomment the implementation in
   `android/app/src/main/kotlin/digital/thinkport/ambientnav/AmbientNavCarAppService.kt`
   (a `NavigationTemplate` updated from the MethodChannel).
4. Test with the **Desktop Head Unit (DHU)** from the Android Auto SDK.

## Why this is gated

CarPlay needs an Apple entitlement and Android Auto navigation needs Google
review; neither can be verified in CI here. Keeping the native heads behind a
manual enable step means the app builds and ships for phones today while the car
integration is ready to switch on once the platform approvals are in place.
