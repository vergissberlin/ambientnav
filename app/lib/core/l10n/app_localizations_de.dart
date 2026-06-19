// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'AmbientNav';

  @override
  String get navTab => 'Navigation';

  @override
  String get controllersTab => 'Controller';

  @override
  String get settingsTab => 'Einstellungen';

  @override
  String get searchDestination => 'Ziel suchen';

  @override
  String get planRoute => 'Route planen';

  @override
  String get startNavigation => 'Navigation starten';

  @override
  String get stopNavigation => 'Beenden';

  @override
  String get downloadOffline => 'Für Offline-Nutzung herunterladen';

  @override
  String get offlineReady => 'Offline-Route bereit';

  @override
  String get noRouteFound => 'Keine Route gefunden';

  @override
  String get locationPermissionDenied =>
      'Standortberechtigung ist für die Navigation erforderlich';

  @override
  String get routeOverview => 'Routenübersicht';

  @override
  String get followRoute => 'Route folgen';

  @override
  String get developer => 'Entwickler';

  @override
  String get developerDesc => 'Werkzeuge für Entwicklung und Tests';

  @override
  String get routeSimulation => 'Routensimulation';

  @override
  String get routeSimulationDesc =>
      'Ein virtuelles Fahrzeug entlang der geplanten Route fahren';

  @override
  String get voiceGuidance => 'Sprachausgabe';

  @override
  String get theme => 'Design';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get language => 'Sprache';

  @override
  String get scanForControllers => 'Nach Controllern suchen';

  @override
  String get scanning => 'Suche läuft…';

  @override
  String get noControllers => 'Keine Controller gefunden';

  @override
  String get connect => 'Verbinden';

  @override
  String get disconnect => 'Trennen';

  @override
  String get connected => 'Verbunden';

  @override
  String get signalStrength => 'Signal';

  @override
  String get battery => 'Batterie';

  @override
  String voltage(String volts) {
    return '$volts V';
  }

  @override
  String firmwareVersion(String version) {
    return 'Firmware $version';
  }

  @override
  String get roleFront => 'Vorne';

  @override
  String get roleRear => 'Hinten';

  @override
  String get ledConfig => 'LED-Konfiguration';

  @override
  String get ledCount => 'Anzahl LEDs';

  @override
  String get brightness => 'Helligkeit';

  @override
  String get effect => 'Effekt';

  @override
  String get sensorConfig => 'Sensor-Konfiguration';

  @override
  String get activeSensor => 'Aktiver Sensor';

  @override
  String get calibration => 'Kalibrierungs-Offset (cm)';

  @override
  String get maxRange => 'Maximale Reichweite (cm)';

  @override
  String get calibrate => 'Kalibrieren';

  @override
  String get save => 'Speichern';

  @override
  String get read => 'Vom Controller lesen';

  @override
  String get firmwareUpdate => 'Firmware-Update';

  @override
  String get selectFirmware => 'Firmware-Datei auswählen';

  @override
  String get installUpdate => 'Update installieren';

  @override
  String get updating => 'Update läuft…';

  @override
  String get updateDone => 'Update abgeschlossen';

  @override
  String get updateFailed => 'Update fehlgeschlagen';

  @override
  String get pairing => 'Kopplung erforderlich';

  @override
  String get enterPasskey => '6-stelligen Passkey vom Controller eingeben';

  @override
  String get passkey => 'Passkey';

  @override
  String get pair => 'Koppeln';

  @override
  String get notPaired =>
      'Nicht gekoppelt — Konfiguration und Updates gesperrt';

  @override
  String get wrongPasskey => 'Falscher Passkey';

  @override
  String get paired => 'Gekoppelt';

  @override
  String get sensorLeft => 'Links';

  @override
  String get sensorCenter => 'Mitte';

  @override
  String get sensorRight => 'Rechts';

  @override
  String get sensorFused => 'Kombiniert';
}
