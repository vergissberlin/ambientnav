import 'package:ambientnav/features/controllers/domain/entities/nav_command.dart';
import 'package:ambientnav/features/navigation/domain/entities/maneuver.dart';
import 'package:ambientnav/features/navigation/domain/usecases/maneuver_to_ble_command.dart';
import 'package:flutter_test/flutter_test.dart';

Maneuver _m(ManeuverType t) => Maneuver(
    type: t, instruction: '', distanceMeters: 0, latitude: 0, longitude: 0);

void main() {
  const usecase = ManeuverToBleCommand();

  test('maps maneuver types to nav directions', () {
    expect(usecase(_m(ManeuverType.turnLeft), 50).direction, NavDirection.left);
    expect(usecase(_m(ManeuverType.slightRight), 50).direction,
        NavDirection.right);
    expect(usecase(_m(ManeuverType.straight), 50).direction,
        NavDirection.straight);
    expect(usecase(_m(ManeuverType.arrive), 50).direction, NavDirection.none);
  });

  test('quantizes distance to whole metres and caps at 255', () {
    expect(usecase(_m(ManeuverType.turnLeft), 49.6).distanceM, 50);
    expect(usecase(_m(ManeuverType.turnLeft), 9999).distanceM, 255);
  });

  test('passes through blinker state', () {
    final cmd = usecase(_m(ManeuverType.turnRight), 30, blinker: Blinker.right);
    expect(cmd.blinker, Blinker.right);
  });
}
