/// Which end of the vehicle a controller drives.
///
/// Mirrors the firmware roles: the front ESP32 is the BLE master that also
/// drives the front LED strip; the rear ESP32 drives the sensors and rear strip.
enum ControllerRole {
  front,
  rear;

  /// Wire encoding used by the device-info characteristic (`…DEF4`).
  int get wireValue => index;

  static ControllerRole fromWire(int value) {
    return value == ControllerRole.rear.wireValue
        ? ControllerRole.rear
        : ControllerRole.front;
  }
}
