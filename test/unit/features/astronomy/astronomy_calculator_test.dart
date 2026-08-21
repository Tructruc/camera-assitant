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
    expect(output.recommendedShutterSeconds, closeTo(output.npfSeconds, 0.001));
    expect(output.path, hasLength(7));
    expect(
      output.path[3].altitudeDegrees,
      closeTo(output.altitudeDegrees, 0.001),
    );
  });

  test('selected rule and tolerance alter the recommendation', () {
    final strict = calculator
        .calculate(
          AstronomyInput(
            observerLatitudeDegrees: 51.4779,
            observerLongitudeDegrees: 0,
            instantUtc: DateTime.utc(2026, 1, 15, 22),
            target: CelestialTarget.sirius,
            focalLengthMm: 24,
            cropFactor: 1,
            aperture: 2,
            pixelPitchMicrometres: 5,
            desiredTrailDegrees: 30,
            selectedRule: StarShutterRule.rule500,
            sharpnessTolerance: StarSharpnessTolerance.strict,
          ),
        )
        .output!;
    expect(
      strict.recommendedShutterSeconds,
      closeTo(strict.rule500Seconds * 0.75, 0.001),
    );
  });

  test('ships a categorized offline deep-sky catalog', () {
    expect(CelestialTarget.values.length, greaterThanOrEqualTo(12));
    expect(
      CelestialTarget.values.map((target) => target.category).toSet(),
      containsAll(TargetCategory.values),
    );
  });

  test('moving planets change equatorial position over time', () {
    final first = CelestialTarget.jupiter.equatorialAt(
      DateTime.utc(2026, 1, 1),
    );
    final later = CelestialTarget.jupiter.equatorialAt(
      DateTime.utc(2026, 7, 1),
    );
    expect(first.$1, isNot(closeTo(later.$1, 0.01)));
    expect(first.$1, inInclusiveRange(0, 360));
    expect(first.$2, inInclusiveRange(-90, 90));
  });

  test('Jupiter agrees with the documented JPL Horizons fixture', () {
    final coordinates = CelestialTarget.jupiter.equatorialAt(
      DateTime.utc(2026, 1, 1),
    );
    expect(coordinates.$1, closeTo(112.72933, 0.25));
    expect(coordinates.$2, closeTo(22.03458, 0.25));
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
