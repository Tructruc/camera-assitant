import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/features/planning/domain/north_reference.dart';

void main() {
  test(
    'converts true and magnetic bearings with east-positive declination',
    () {
      expect(NorthReferenceBearing.trueToMagnetic(100, 7), 93);
      expect(NorthReferenceBearing.magneticToTrue(93, 7), 100);
      expect(NorthReferenceBearing.trueToMagnetic(2, 7), 355);
    },
  );

  test('rejects missing and impossible declination', () {
    expect(
      () => NorthReferenceBearing.trueToMagnetic(100, double.nan),
      throwsFormatException,
    );
    expect(
      () => NorthReferenceBearing.trueToMagnetic(100, 91),
      throwsFormatException,
    );
  });

  test('compares true targets with magnetic device headings', () {
    expect(
      NorthReferenceBearing.deviceHeadingDelta(
        trueTargetDegrees: 100,
        magneticHeadingDegrees: 80,
        declinationDegrees: 7,
      ),
      13,
    );
    expect(
      NorthReferenceBearing.deviceHeadingDelta(
        trueTargetDegrees: 2,
        magneticHeadingDegrees: 350,
        declinationDegrees: 7,
      ),
      5,
    );
  });
}
