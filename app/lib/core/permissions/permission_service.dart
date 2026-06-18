import 'package:permission_handler/permission_handler.dart';

/// Requests the runtime permissions BLE scanning needs.
///
/// Android 12+ needs `bluetoothScan` + `bluetoothConnect`; older Android needs
/// location. iOS surfaces Bluetooth via the Info.plist usage string and the
/// `bluetooth` permission. Kept thin so it can be skipped under the mock.
class PermissionService {
  const PermissionService();

  /// Request the permissions required to scan/connect. Returns true when all
  /// required permissions are granted.
  Future<bool> ensureBlePermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    // On platforms where a permission is irrelevant it resolves to granted or
    // permanentlyDenied=false; treat "denied" of the BLE ones as the blocker.
    final scanOk = statuses[Permission.bluetoothScan]?.isGranted ?? true;
    final connectOk = statuses[Permission.bluetoothConnect]?.isGranted ?? true;
    return scanOk && connectOk;
  }
}
