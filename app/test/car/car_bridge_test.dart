import 'package:ambientnav/features/car/car_bridge.dart';
import 'package:ambientnav/features/car/car_session_state.dart';
import 'package:ambientnav/features/navigation/domain/entities/maneuver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CarBridge.encode', () {
    test('encodes an active navigation snapshot', () {
      const state = CarSessionState(
        isNavigating: true,
        nextManeuver: Maneuver(
          type: ManeuverType.turnLeft,
          instruction: 'Turn left onto Main St',
          distanceMeters: 120,
          latitude: 52.5,
          longitude: 13.4,
        ),
        distanceToManeuverMeters: 120,
      );
      final map = CarBridge.encode(state);
      expect(map['isNavigating'], true);
      expect(map['maneuver'], 'turnLeft');
      expect(map['instruction'], 'Turn left onto Main St');
      expect(map['distanceMeters'], 120);
    });

    test('encodes an idle snapshot with no maneuver', () {
      const state = CarSessionState(isNavigating: false);
      final map = CarBridge.encode(state);
      expect(map['isNavigating'], false);
      expect(map['maneuver'], isNull);
      expect(map['instruction'], '');
    });
  });
}
