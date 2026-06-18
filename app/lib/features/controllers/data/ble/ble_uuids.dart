/// All BLE GATT UUIDs for the AmbientNav front controller.
///
/// The base `12345678-1234-5678-1234-56789ABCDExx` family extends the existing
/// firmware navigation service. The navigation service/characteristic
/// (`…DEF0` / `…DEF1`) are already implemented in firmware; the remaining
/// services are the documented extension implemented by the app's codecs and
/// awaiting firmware support.
class BleUuids {
  const BleUuids._();

  static const String _base = '12345678-1234-5678-1234-56789abcde';

  static String _u(String suffix) => '$_base$suffix';

  // Navigation (existing in firmware).
  static final String navService = _u('f0');
  static final String navCharacteristic = _u('f1');

  // Telemetry.
  static final String telemetryService = _u('f2');
  static final String voltageCharacteristic = _u('f3'); // Read/Notify, u16 mV
  static final String deviceInfoCharacteristic = _u('f4'); // Read, role + fw

  // LED configuration.
  static final String ledConfigService = _u('f5');
  static final String ledConfigCharacteristic = _u('f6'); // Read/Write

  // Sensor configuration.
  static final String sensorConfigService = _u('f7');
  static final String sensorConfigCharacteristic = _u('f8'); // Read/Write

  // OTA firmware update.
  static final String otaService = _u('f9');
  static final String otaControlCharacteristic = _u('fa'); // Write/Notify
  static final String otaDataCharacteristic =
      _u('fb'); // Write Without Response
}
