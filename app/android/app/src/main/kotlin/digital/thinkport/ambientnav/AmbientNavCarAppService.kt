// Android Auto CarAppService — REFERENCE TEMPLATE (not yet wired into the build).
//
// Enabling Android Auto navigation requires the Jetpack Car App library
// (androidx.car.app:app + app-projected) in build.gradle, a <service> +
// automotive_app_desc.xml in the manifest, and (for distribution) Google review.
// Those are deliberately not added here so the standard `flutter build apk`
// stays green; see app/docs/car-integration.md for the enabling steps.
//
// It exposes a NavigationTemplate and updates a maneuver routing-info panel from
// the `digital.thinkport.ambientnav/car` MethodChannel fed by CarBridge (Dart).

package digital.thinkport.ambientnav

/*
import androidx.car.app.CarAppService
import androidx.car.app.Session
import androidx.car.app.Screen
import androidx.car.app.validation.HostValidator
import androidx.car.app.model.Template
import androidx.car.app.navigation.model.NavigationTemplate
import androidx.car.app.navigation.model.RoutingInfo
import androidx.car.app.navigation.model.Maneuver
import androidx.car.app.model.CarText

class AmbientNavCarAppService : CarAppService() {
    override fun createHostValidator(): HostValidator =
        HostValidator.ALLOW_ALL_HOSTS_VALIDATOR // tighten for production

    override fun onCreateSession(): Session = AmbientNavSession()
}

class AmbientNavSession : Session() {
    override fun onCreateScreen(intent: android.content.Intent): Screen =
        NavScreen(carContext)
}

class NavScreen(carContext: androidx.car.app.CarContext) : Screen(carContext) {
    // A MethodChannel ("digital.thinkport.ambientnav/car") supplies the latest
    // CarSessionState (maneuver, instruction, distance); invalidate() on update.
    override fun onGetTemplate(): Template {
        return NavigationTemplate.Builder()
            .setNavigationInfo(
                RoutingInfo.Builder()
                    .setCurrentStep(
                        androidx.car.app.navigation.model.Step.Builder()
                            .setCue(CarText.create("Next maneuver"))
                            .build(),
                        androidx.car.app.model.Distance.create(
                            0.0, androidx.car.app.model.Distance.UNIT_METERS)
                    )
                    .build()
            )
            .build()
    }
}
*/
