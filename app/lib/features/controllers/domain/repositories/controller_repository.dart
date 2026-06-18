import '../entities/controller_info.dart';
import '../entities/led_config.dart';
import '../entities/nav_command.dart';
import '../entities/ota_update.dart';
import '../entities/sensor_config.dart';
import '../entities/telemetry.dart';

/// The contract the UI and use-cases depend on. Implemented by the real BLE
/// repository (`flutter_blue_plus`) and the in-memory mock used in dev and CI.
///
/// Security: [pair] must succeed (bonded, encrypted link) before
/// [writeLedConfig], [writeSensorConfig] or [startOta] are permitted. Reading
/// telemetry / configs is allowed without pairing where the firmware exposes
/// it openly. Implementations throw [NotPairedException] otherwise.
abstract interface class ControllerRepository {
  /// Emits the current set of discovered controllers (with live RSSI) while a
  /// scan is active.
  Stream<List<ControllerInfo>> scan();

  Future<void> stopScan();

  Future<void> connect(String id);
  Future<void> disconnect(String id);

  /// Establish a bonded, encrypted link using the 6-digit [passkey] printed on
  /// / shipped with the controller. Throws [WrongPasskeyException] on mismatch.
  Future<void> pair(String id, String passkey);

  /// Live telemetry (voltage + RSSI) for a connected controller.
  Stream<Telemetry> telemetry(String id);

  Future<LedConfig> readLedConfig(String id);
  Future<void> writeLedConfig(String id, LedConfig config);

  Future<SensorConfig> readSensorConfig(String id);
  Future<void> writeSensorConfig(String id, SensorConfig config);

  /// Send the compact 3-byte navigation packet (existing firmware feature).
  Future<void> sendNavCommand(String id, NavCommand command);

  /// Stream OTA progress while transferring [firmware] (raw .bin bytes).
  Stream<OtaProgress> startOta(String id, List<int> firmware);
}
