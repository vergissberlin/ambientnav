import '../../domain/entities/controller_info.dart';
import '../../domain/entities/controller_role.dart';

/// Pure helpers used by [BleControllerRepository], split out so they can be
/// unit-tested without BLE hardware or the flutter_blue_plus types.
class BleMapping {
  const BleMapping._();

  /// Whether an advertisement belongs to an AmbientNav controller: it either
  /// advertises the nav service UUID or its name starts with "AmbientNav".
  static bool isAmbientNavDevice({
    required List<String> advertisedServiceUuids,
    required String name,
    required String navServiceUuid,
  }) {
    final lowerNav = navServiceUuid.toLowerCase();
    final advertises =
        advertisedServiceUuids.any((u) => u.toLowerCase() == lowerNav);
    return advertises || name.toLowerCase().startsWith('ambientnav');
  }

  /// Infer the controller role from its advertised/platform name.
  static ControllerRole roleFromName(String name) {
    return name.toLowerCase().contains('rear')
        ? ControllerRole.rear
        : ControllerRole.front;
  }

  /// Build a [ControllerInfo] from primitive scan fields (keeps the repository
  /// free of mapping logic and makes this unit-testable).
  static ControllerInfo controllerInfoFrom({
    required String id,
    required String name,
    required int rssi,
  }) {
    return ControllerInfo(
      id: id,
      name: name.isEmpty ? 'AmbientNav' : name,
      rssi: rssi,
      role: roleFromName(name),
    );
  }
}
