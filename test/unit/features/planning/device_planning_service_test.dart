import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/features/planning/data/device_planning_service.dart';

void main() {
  test('an unusable altitude is reported as unknown, never as sea level', () {
    // Geolocator returns 0 for both fields when there is no vertical fix.
    expect(elevationFromAltitude(altitude: 0, altitudeAccuracy: 0), isNull);
    // A real sea-level reading has a positive accuracy, so it is kept.
    expect(elevationFromAltitude(altitude: 0, altitudeAccuracy: 5), 0);
    expect(elevationFromAltitude(altitude: 46, altitudeAccuracy: 8), 46);
    // A non-finite altitude is never trusted.
    expect(
      elevationFromAltitude(altitude: double.nan, altitudeAccuracy: 8),
      isNull,
    );
    expect(
      elevationFromAltitude(altitude: double.infinity, altitudeAccuracy: 8),
      isNull,
    );
  });
}
