import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/features/astronomy/domain/astronomy_calculator.dart';

import '../../../fixtures/astronomy_fixtures.dart';

void main() {
  const calculator = AstronomyCalculator();

  test('places Sirius for the documented Greenwich fixture', () {
    final output = calculator.calculate(greenwichSiriusFixture).output!;
    expect(output.altitudeDegrees, closeTo(20.40, 0.25));
    expect(output.azimuthDegrees, closeTo(163.72, 0.25));
    expect(output.isAboveHorizon, isTrue);
    expect(
      output.events.map((event) => event.type),
      containsAll(CelestialEventType.values),
    );
  });

  test('identifies Polaris as circumpolar from Greenwich', () {
    final output = calculator
        .calculate(
          AstronomyInput(
            observerLatitudeDegrees: 51.4779,
            observerLongitudeDegrees: 0,
            instantUtc: DateTime.utc(2026, 1, 15, 22),
            target: CelestialTarget.polaris,
            focalLengthMm: 50,
            cropFactor: 1,
            aperture: 2,
            pixelPitchMicrometres: 5,
            desiredTrailDegrees: 15,
          ),
        )
        .output!;
    expect(output.visibilityCycle, VisibilityCycle.circumpolar);
    expect(output.events.map((event) => event.type), [
      CelestialEventType.transit,
    ]);
  });

  test('calculates 500, NPF, and star-trail guidance', () {
    final output = calculator.calculate(greenwichSiriusFixture).output!;
    expect(output.rule500Seconds, closeTo(20.833, 0.001));
    expect(output.npfSeconds, closeTo(10.333, 0.001));
    expect(output.trailDurationSeconds, closeTo(7180.34, 0.1));
    expect(output.path, hasLength(7));
    expect(
      output.path[3].altitudeDegrees,
      closeTo(output.altitudeDegrees, 0.001),
    );
  });

  test('ships a categorized offline deep-sky catalog', () {
    expect(CelestialTarget.values.length, greaterThanOrEqualTo(12));
    expect(
      CelestialTarget.values.map((target) => target.category).toSet(),
      containsAll(TargetCategory.values),
    );
  });

  test('rejects invalid location, optics, and trail inputs', () {
    final result = calculator.calculate(
      AstronomyInput(
        observerLatitudeDegrees: 91,
        observerLongitudeDegrees: 181,
        instantUtc: DateTime.utc(2026),
        target: CelestialTarget.sirius,
        focalLengthMm: 0,
        cropFactor: -1,
        aperture: double.nan,
        pixelPitchMicrometres: 0,
        desiredTrailDegrees: 361,
      ),
    );
    expect(result.output, isNull);
    expect(result.errors, hasLength(7));
  });
}
