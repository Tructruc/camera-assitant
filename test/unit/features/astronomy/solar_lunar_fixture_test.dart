import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/features/astronomy/domain/astronomy_calculator.dart';
import 'package:photography_assistant/features/astronomy/domain/solar_lunar_ephemeris.dart';

import '../../../fixtures/astronomy_fixtures.dart';

/// Externally traceable Sun, Moon, and Sirius references, asserted at the
/// product's declared planning tolerance. See `test/fixtures/astronomy/README.md`
/// for the queries, sources, and the measured deviations.
void main() {
  const calculator = AstronomyCalculator();
  const ephemeris = SolarLunarEphemeris();

  test('solar geocentric coordinates match the JPL Horizons table', () {
    final coordinates = ephemeris.equatorial(
      SolarLunarBody.sun,
      DateTime.utc(2026, 3, 20, 12),
    );
    expect(
      _separation(
        coordinates.$1,
        coordinates.$2,
        horizonsSunGeocentric.ra,
        horizonsSunGeocentric.dec,
      ),
      lessThan(0.25),
    );
  });

  test('lunar geocentric coordinates stay inside the declared lunar bound', () {
    final coordinates = ephemeris.equatorial(
      SolarLunarBody.moon,
      DateTime.utc(2026, 6, 1),
    );
    expect(
      _separation(
        coordinates.$1,
        coordinates.$2,
        horizonsMoonGeocentric.ra,
        horizonsMoonGeocentric.dec,
      ),
      lessThan(2.0),
    );
  });

  test(
    'solar topocentric position matches the JPL Horizons observer table',
    () {
      final output = calculator
          .calculate(
            greenwichFixture(
              target: CelestialTarget.sun,
              instantUtc: DateTime.utc(2026, 3, 20, 12),
            ),
          )
          .output!;
      expect(
        _separation(
          output.azimuthDegrees,
          output.altitudeDegrees,
          horizonsSunTopocentric.azimuth,
          horizonsSunTopocentric.altitude,
        ),
        lessThan(0.25),
      );
    },
  );

  test(
    'lunar topocentric position matches the JPL Horizons observer table',
    () {
      final output = calculator
          .calculate(
            greenwichFixture(
              target: CelestialTarget.moon,
              instantUtc: DateTime.utc(2026, 6, 1),
            ),
          )
          .output!;
      expect(
        _separation(
          output.azimuthDegrees,
          output.altitudeDegrees,
          horizonsMoonTopocentric.azimuth,
          horizonsMoonTopocentric.altitude,
        ),
        lessThan(2.0),
      );
    },
  );

  test('Sirius catalog coordinates match the SIMBAD ICRS position', () {
    expect(
      _separation(
        CelestialTarget.sirius.rightAscensionDegrees,
        CelestialTarget.sirius.declinationDegrees,
        simbadSiriusIcrs.ra,
        simbadSiriusIcrs.dec,
      ),
      lessThan(0.01),
    );
  });

  test('solar rise, transit, and set match the USNO one-day table', () {
    final output = calculator
        .calculate(
          greenwichFixture(
            target: CelestialTarget.sun,
            instantUtc: DateTime.utc(2026, 3, 20),
          ),
        )
        .output!;
    final transit = output.events
        .firstWhere((event) => event.type == CelestialEventType.transit)
        .instantUtc;
    expect(
      (_minutesUtc(transit) - _minutesOf(usnoGreenwichSun.transit)).abs(),
      lessThan(2.0),
    );
    expect(output.visibilityCycle, VisibilityCycle.risesAndSets);
    expect(output.events.map((event) => event.type), [
      CelestialEventType.rise,
      CelestialEventType.transit,
      CelestialEventType.set,
    ]);

    // The planner reports the airless geometric horizon. At the USNO rise and
    // set instants the solar centre therefore sits at the standard refraction
    // plus semidiameter offset of -0.8333°, which is what makes the published
    // times differ from the model's zero-altitude crossings.
    for (final reference in [usnoGreenwichSun.rise, usnoGreenwichSun.set]) {
      final atReference = calculator
          .calculate(
            greenwichFixture(
              target: CelestialTarget.sun,
              instantUtc: _utcOn20260320(reference),
            ),
          )
          .output!;
      expect(atReference.altitudeDegrees, closeTo(-0.8333, 0.05));
    }
  });

  test('lunar rise, transit, and set stay inside the declared lunar bound', () {
    final output = calculator
        .calculate(
          greenwichFixture(
            target: CelestialTarget.moon,
            instantUtc: DateTime.utc(2026, 3, 20),
          ),
        )
        .output!;
    expect(output.visibilityCycle, VisibilityCycle.risesAndSets);
    final rise = output.events.firstWhere(
      (event) => event.type == CelestialEventType.rise,
    );
    final transit = output.events.firstWhere(
      (event) => event.type == CelestialEventType.transit,
    );
    final set = output.events.firstWhere(
      (event) => event.type == CelestialEventType.set,
    );
    expect(rise.instantUtc.isBefore(transit.instantUtc), isTrue);
    expect(transit.instantUtc.isBefore(set.instantUtc), isTrue);
    // The USNO lunar transit is a meridian crossing like ours, but its rise and
    // set use the lunar horizon convention rather than a geometric zero
    // altitude, so only the transit is asserted tightly.
    expect(
      (_minutesUtc(transit.instantUtc) - _minutesOf(usnoGreenwichMoon.transit))
          .abs(),
      lessThan(10.0),
    );
    for (final event in [rise, set]) {
      final reference = event.type == CelestialEventType.rise
          ? usnoGreenwichMoon.rise
          : usnoGreenwichMoon.set;
      expect(
        (_minutesUtc(event.instantUtc) - _minutesOf(reference)).abs(),
        lessThan(20.0),
      );
    }
  });

  test('solar visibility cycle reports circumpolar and never-rises bounds', () {
    final polarDay = calculator
        .calculate(
          greenwichFixture(
            target: CelestialTarget.sun,
            instantUtc: DateTime.utc(2026, 6, 21),
            latitudeDegrees: 80,
          ),
        )
        .output!;
    expect(polarDay.visibilityCycle, VisibilityCycle.circumpolar);
    expect(polarDay.events.map((event) => event.type), [
      CelestialEventType.transit,
    ]);

    final polarNight = calculator
        .calculate(
          greenwichFixture(
            target: CelestialTarget.sun,
            instantUtc: DateTime.utc(2026, 6, 21),
            latitudeDegrees: -80,
          ),
        )
        .output!;
    expect(polarNight.visibilityCycle, VisibilityCycle.neverRises);
    expect(polarNight.events.map((event) => event.type), [
      CelestialEventType.transit,
    ]);
  });

  test('the Sun carries solar-safety guidance and the Moon does not', () {
    final sun = calculator.calculate(
      greenwichFixture(
        target: CelestialTarget.sun,
        instantUtc: DateTime.utc(2026, 3, 20, 12),
      ),
    );
    final moon = calculator.calculate(
      greenwichFixture(
        target: CelestialTarget.moon,
        instantUtc: DateTime.utc(2026, 3, 20, 12),
      ),
    );
    expect(
      sun.warnings.map((warning) => warning.code),
      contains('solarSafety'),
    );
    expect(sun.output!.path, hasLength(7));
    expect(
      moon.warnings.map((warning) => warning.code),
      isNot(contains('solarSafety')),
    );
    expect(moon.output!.path, hasLength(7));
  });
}

/// Angular separation in degrees between two spherical positions.
double _separation(double first, double second, double third, double fourth) {
  final firstAngle = _radians(first);
  final secondAngle = _radians(second);
  final thirdAngle = _radians(third);
  final fourthAngle = _radians(fourth);
  final cosine =
      math.sin(firstAngle) * math.sin(thirdAngle) +
      math.cos(firstAngle) *
          math.cos(thirdAngle) *
          math.cos(secondAngle - fourthAngle);
  return _degrees(math.acos(cosine.clamp(-1.0, 1.0)));
}

double _radians(double value) => value * math.pi / 180;
double _degrees(double value) => value * 180 / math.pi;

double _minutesUtc(DateTime instant) =>
    instant.hour * 60 + instant.minute + instant.second / 60;

double _minutesOf(String hhmm) {
  final parts = hhmm.split(':');
  return int.parse(parts[0]) * 60.0 + int.parse(parts[1]);
}

DateTime _utcOn20260320(String hhmm) {
  final parts = hhmm.split(':');
  return DateTime.utc(2026, 3, 20, int.parse(parts[0]), int.parse(parts[1]));
}
