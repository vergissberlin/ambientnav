import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AmbientNav'**
  String get appTitle;

  /// No description provided for @navTab.
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navTab;

  /// No description provided for @controllersTab.
  ///
  /// In en, this message translates to:
  /// **'Controllers'**
  String get controllersTab;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTab;

  /// No description provided for @searchDestination.
  ///
  /// In en, this message translates to:
  /// **'Search destination'**
  String get searchDestination;

  /// No description provided for @planRoute.
  ///
  /// In en, this message translates to:
  /// **'Plan route'**
  String get planRoute;

  /// No description provided for @startNavigation.
  ///
  /// In en, this message translates to:
  /// **'Start navigation'**
  String get startNavigation;

  /// No description provided for @stopNavigation.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopNavigation;

  /// No description provided for @downloadOffline.
  ///
  /// In en, this message translates to:
  /// **'Download for offline use'**
  String get downloadOffline;

  /// No description provided for @offlineReady.
  ///
  /// In en, this message translates to:
  /// **'Offline route ready'**
  String get offlineReady;

  /// No description provided for @noRouteFound.
  ///
  /// In en, this message translates to:
  /// **'No route found'**
  String get noRouteFound;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @developerDesc.
  ///
  /// In en, this message translates to:
  /// **'Tools for development and testing'**
  String get developerDesc;

  /// No description provided for @routeSimulation.
  ///
  /// In en, this message translates to:
  /// **'Route simulation'**
  String get routeSimulation;

  /// No description provided for @routeSimulationDesc.
  ///
  /// In en, this message translates to:
  /// **'Drive a virtual vehicle along the planned route'**
  String get routeSimulationDesc;

  /// No description provided for @voiceGuidance.
  ///
  /// In en, this message translates to:
  /// **'Voice guidance'**
  String get voiceGuidance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @scanForControllers.
  ///
  /// In en, this message translates to:
  /// **'Scan for controllers'**
  String get scanForControllers;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get scanning;

  /// No description provided for @noControllers.
  ///
  /// In en, this message translates to:
  /// **'No controllers found'**
  String get noControllers;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @signalStrength.
  ///
  /// In en, this message translates to:
  /// **'Signal'**
  String get signalStrength;

  /// No description provided for @battery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get battery;

  /// No description provided for @voltage.
  ///
  /// In en, this message translates to:
  /// **'{volts} V'**
  String voltage(String volts);

  /// No description provided for @firmwareVersion.
  ///
  /// In en, this message translates to:
  /// **'Firmware {version}'**
  String firmwareVersion(String version);

  /// No description provided for @roleFront.
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get roleFront;

  /// No description provided for @roleRear.
  ///
  /// In en, this message translates to:
  /// **'Rear'**
  String get roleRear;

  /// No description provided for @ledConfig.
  ///
  /// In en, this message translates to:
  /// **'LED configuration'**
  String get ledConfig;

  /// No description provided for @ledCount.
  ///
  /// In en, this message translates to:
  /// **'Number of LEDs'**
  String get ledCount;

  /// No description provided for @brightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get brightness;

  /// No description provided for @effect.
  ///
  /// In en, this message translates to:
  /// **'Effect'**
  String get effect;

  /// No description provided for @sensorConfig.
  ///
  /// In en, this message translates to:
  /// **'Sensor configuration'**
  String get sensorConfig;

  /// No description provided for @activeSensor.
  ///
  /// In en, this message translates to:
  /// **'Active sensor'**
  String get activeSensor;

  /// No description provided for @calibration.
  ///
  /// In en, this message translates to:
  /// **'Calibration offset (cm)'**
  String get calibration;

  /// No description provided for @maxRange.
  ///
  /// In en, this message translates to:
  /// **'Max range (cm)'**
  String get maxRange;

  /// No description provided for @calibrate.
  ///
  /// In en, this message translates to:
  /// **'Calibrate'**
  String get calibrate;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @read.
  ///
  /// In en, this message translates to:
  /// **'Read from controller'**
  String get read;

  /// No description provided for @firmwareUpdate.
  ///
  /// In en, this message translates to:
  /// **'Firmware update'**
  String get firmwareUpdate;

  /// No description provided for @selectFirmware.
  ///
  /// In en, this message translates to:
  /// **'Select firmware file'**
  String get selectFirmware;

  /// No description provided for @installUpdate.
  ///
  /// In en, this message translates to:
  /// **'Install update'**
  String get installUpdate;

  /// No description provided for @updating.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get updating;

  /// No description provided for @updateDone.
  ///
  /// In en, this message translates to:
  /// **'Update complete'**
  String get updateDone;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get updateFailed;

  /// No description provided for @pairing.
  ///
  /// In en, this message translates to:
  /// **'Pairing required'**
  String get pairing;

  /// No description provided for @enterPasskey.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit passkey from your controller'**
  String get enterPasskey;

  /// No description provided for @passkey.
  ///
  /// In en, this message translates to:
  /// **'Passkey'**
  String get passkey;

  /// No description provided for @pair.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get pair;

  /// No description provided for @notPaired.
  ///
  /// In en, this message translates to:
  /// **'Not paired — config and updates are locked'**
  String get notPaired;

  /// No description provided for @wrongPasskey.
  ///
  /// In en, this message translates to:
  /// **'Wrong passkey'**
  String get wrongPasskey;

  /// No description provided for @paired.
  ///
  /// In en, this message translates to:
  /// **'Paired'**
  String get paired;

  /// No description provided for @sensorLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get sensorLeft;

  /// No description provided for @sensorCenter.
  ///
  /// In en, this message translates to:
  /// **'Center'**
  String get sensorCenter;

  /// No description provided for @sensorRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get sensorRight;

  /// No description provided for @sensorFused.
  ///
  /// In en, this message translates to:
  /// **'Fused'**
  String get sensorFused;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
