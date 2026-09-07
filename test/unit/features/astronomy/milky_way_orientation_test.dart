import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/features/astronomy/domain/astronomy_calculator.dart';

void main() {
  const calculator = AstronomyCalculator();

  AstronomyInput input(
    double latitude,
    double longitude,
    DateTime instant, {
    CelestialTarget target = CelestialTarget.milkyWayCore,
  }) => AstronomyInput(
    observerLatitudeDegrees: latitude,
    observerLongitudeDegrees: longitude,
    instantUtc: instant,
    target: target,
    focalLengthMm: 24,
    cropFactor: 1,
    aperture: 2.8,
    pixelPitchMicrometres: 5,
    desiredTrailDegrees: 30,
  );

  // Independently derived spherical position-angle fixtures. The production
  // implementation projects Cartesian tangent vectors; see fixture provenance.
  for (final fixture in <(String, double, double, String, double)>[
    ('Greenwich evening', 51.4779, 0, '2026-07-01T22:00:00Z', 131.660662),
    ('Greenwich morning', 51.4779, 0, '2026-07-02T02:00:00Z', 95.899654),
    ('Sydney', -33.8688, 151.2093, '2026-07-01T12:00:00Z', 55.381327),
    ('equator', 0, 0, '2026-07-01T22:00:00Z', 152.732536),
    ('below horizon', 51.4779, 0, '2026-07-01T10:00:00Z', 96.733879),
    ('north pole', 90, 0, '2026-07-01T22:00:00Z', 121.395578),
    ('south pole', -90, 0, '2026-07-01T22:00:00Z', 121.395578),
  ]) {
    test('projects the Milky Way axis for ${fixture.$1}', () {
      final result = calculator.calculate(
        input(fixture.$2, fixture.$3, DateTime.parse(fixture.$4)),
      );
      expect(
        result.output!.milkyWayOrientationDegrees,
        closeTo(fixture.$5, 0.00001),
      );
      expect(result.formulaVersion, 2);
      expect(
        result.assumptions.map((item) => item.value),
        contains(AstronomyCalculator.milkyWayOrientationConvention),
      );
      if (fixture.$1 == 'below horizon') {
        expect(result.output!.isAboveHorizon, isFalse);
      }
    });
  }

  test('omits Milky Way orientation for other targets', () {
    final result = calculator.calculate(
      input(51.4779, 0, DateTime.utc(2026), target: CelestialTarget.sirius),
    );
    expect(result.output!.milkyWayOrientationDegrees, isNull);
    expect(
      result.assumptions.map((item) => item.key),
      isNot(contains('milkyWayOrientation')),
    );
  });

  test(
    'reports undefined orientation within 0.1 degree of zenith or nadir',
    () {
      // At J2000 noon GMST is 280.46061837 degrees; these longitudes put
      // the core exactly on the upper/lower meridian.
      for (final point in [
        (-29.00781, -14.04378837),
        (-28.95781, -14.04378837),
        (29.00781, 165.95621163),
        (29.05781, 165.95621163),
      ]) {
        final result = calculator.calculate(
          input(point.$1, point.$2, DateTime.utc(2000, 1, 1, 12)),
        );
        expect(result.output!.milkyWayOrientationDegrees, isNull);
        expect(result.output!.altitudeDegrees.isFinite, isTrue);
        expect(
          result.warnings.map((item) => item.code),
          contains('milkyWayOrientationUndefined'),
        );
      }
      final outside = calculator.calculate(
        input(-28.80781, -14.04378837, DateTime.utc(2000, 1, 1, 12)),
      );
      expect(outside.output!.milkyWayOrientationDegrees, isNotNull);
    },
  );

  test(
    'wraps the same axis at the date line and stays within 0 to 180 degrees',
    () {
      final instant = DateTime.utc(2026, 7, 1, 22);
      final east = calculator.calculate(input(45, 180, instant)).output!;
      final west = calculator.calculate(input(45, -180, instant)).output!;
      expect(
        east.milkyWayOrientationDegrees,
        closeTo(west.milkyWayOrientationDegrees!, 1e-8),
      );
      for (var hour = 0; hour < 24; hour++) {
        final angle = calculator
            .calculate(input(-33, 151, DateTime.utc(2026, 7, 1, hour)))
            .output!
            .milkyWayOrientationDegrees!;
        expect(angle, greaterThanOrEqualTo(0));
        expect(angle, lessThan(180));
      }
    },
  );
}
