// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AmbientNav';

  @override
  String get navTab => 'Navigate';

  @override
  String get controllersTab => 'Controllers';

  @override
  String get settingsTab => 'Settings';

  @override
  String get searchDestination => 'Search destination';

  @override
  String get planRoute => 'Plan route';

  @override
  String get startNavigation => 'Start navigation';

  @override
  String get stopNavigation => 'Stop';

  @override
  String get downloadOffline => 'Download for offline use';

  @override
  String get offlineReady => 'Offline route ready';

  @override
  String get noRouteFound => 'No route found';

  @override
  String get routeOverview => 'Route overview';

  @override
  String get followRoute => 'Follow route';

  @override
  String get developer => 'Developer';

  @override
  String get developerDesc => 'Tools for development and testing';

  @override
  String get routeSimulation => 'Route simulation';

  @override
  String get routeSimulationDesc =>
      'Drive a virtual vehicle along the planned route';

  @override
  String get voiceGuidance => 'Voice guidance';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get scanForControllers => 'Scan for controllers';

  @override
  String get scanning => 'Scanning…';

  @override
  String get noControllers => 'No controllers found';

  @override
  String get connect => 'Connect';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get connected => 'Connected';

  @override
  String get signalStrength => 'Signal';

  @override
  String get battery => 'Battery';

  @override
  String voltage(String volts) {
    return '$volts V';
  }

  @override
  String firmwareVersion(String version) {
    return 'Firmware $version';
  }

  @override
  String get roleFront => 'Front';

  @override
  String get roleRear => 'Rear';

  @override
  String get ledConfig => 'LED configuration';

  @override
  String get ledCount => 'Number of LEDs';

  @override
  String get brightness => 'Brightness';

  @override
  String get effect => 'Effect';

  @override
  String get sensorConfig => 'Sensor configuration';

  @override
  String get activeSensor => 'Active sensor';

  @override
  String get calibration => 'Calibration offset (cm)';

  @override
  String get maxRange => 'Max range (cm)';

  @override
  String get calibrate => 'Calibrate';

  @override
  String get save => 'Save';

  @override
  String get read => 'Read from controller';

  @override
  String get firmwareUpdate => 'Firmware update';

  @override
  String get selectFirmware => 'Select firmware file';

  @override
  String get installUpdate => 'Install update';

  @override
  String get updating => 'Updating…';

  @override
  String get updateDone => 'Update complete';

  @override
  String get updateFailed => 'Update failed';

  @override
  String get pairing => 'Pairing required';

  @override
  String get enterPasskey => 'Enter the 6-digit passkey from your controller';

  @override
  String get passkey => 'Passkey';

  @override
  String get pair => 'Pair';

  @override
  String get notPaired => 'Not paired — config and updates are locked';

  @override
  String get wrongPasskey => 'Wrong passkey';

  @override
  String get paired => 'Paired';

  @override
  String get sensorLeft => 'Left';

  @override
  String get sensorCenter => 'Center';

  @override
  String get sensorRight => 'Right';

  @override
  String get sensorFused => 'Fused';
}
