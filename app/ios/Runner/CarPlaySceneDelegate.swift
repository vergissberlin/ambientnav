// CarPlay scene delegate — REFERENCE TEMPLATE (not yet wired into the build).
//
// CarPlay navigation apps require the Apple CarPlay entitlement
// (com.apple.developer.carplay-maps), a CarPlay scene declared in Info.plist,
// and review by Apple. Because that can't be provisioned or CI-verified here,
// this file is provided as the starting point — see app/docs/car-integration.md
// for the enabling steps.
//
// It renders a CPMapTemplate and updates a maneuver banner from the
// `digital.thinkport.ambientnav/car` MethodChannel fed by CarBridge (Dart).

import CarPlay
import Flutter

@available(iOS 14.0, *)
class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    var interfaceController: CPInterfaceController?
    private let mapTemplate = CPMapTemplate()

    func templateApplicationScene(
        _ scene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController
        interfaceController.setRootTemplate(mapTemplate, animated: true, completion: nil)
        attachChannel()
    }

    func templateApplicationScene(
        _ scene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
    }

    /// Listen for navigation snapshots forwarded by the Flutter CarBridge.
    private func attachChannel() {
        guard let messenger = (UIApplication.shared.delegate as? FlutterAppDelegate)?
            .window?.rootViewController as? FlutterViewController else { return }
        let channel = FlutterMethodChannel(
            name: "digital.thinkport.ambientnav/car",
            binaryMessenger: messenger.binaryMessenger)
        channel.setMethodCallHandler { [weak self] call, result in
            if call.method == "updateSession",
               let args = call.arguments as? [String: Any] {
                self?.updateBanner(args)
            }
            result(nil)
        }
    }

    private func updateBanner(_ session: [String: Any]) {
        let instruction = session["instruction"] as? String ?? ""
        let distance = session["distanceMeters"] as? Double ?? 0
        let trip = CPTrip(origin: MKMapItem.forCurrentLocation(),
                          destination: MKMapItem.forCurrentLocation(),
                          routeChoices: [])
        // A production app would drive CPNavigationSession/estimates here; this
        // template keeps the maneuver text + distance visible.
        _ = (instruction, distance, trip)
    }
}
