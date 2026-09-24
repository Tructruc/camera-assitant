import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/features/astronomy/domain/astronomy_calculator.dart';

/// Randomized property sweep over the astronomy planner.
///
/// Two kinds of claim, both from the output's own definition. The first is
/// geometry: the altitude and azimuth have to sit in their ranges, the horizon
/// flag has to follow the altitude, and the sampled path the screen draws has
/// to agree with the position reported for the instant in the middle of it. The
/// second is the shutter arithmetic - the 500 rule, the NPF rule and the trail
/// figures are all closed-form in the input, so each is recomputed here and
/// compared, along with the relations between them.
///
/// The inputs deliberately include the polar latitudes, where the sun neither
/// rises nor sets, and every target in the catalogue.
void main() {
  final random = math.Random(20260927);
  const calculator = AstronomyCalculator();

  double uniform(double min, double max) =>
      min + random.nextDouble() * (max - min);

  void expectClose(
    List<String> violations,
    String label,
    double actual,
    double expected,
  ) {
    if (!actual.isFinite) {
      violations.add('$label is $actual (expected $expected)');
      return;
    }
    final tolerance = math.max(expected.abs() * 1e-9, 1e-9);
    if ((actual - expected).abs() > tolerance) {
      violations.add('$label is $actual, should be $expected');
    }
  }

  test('astronomy positions, path and shutter rules agree with their inputs', () {
    final violations = <String>[];
    var refused = 0;

    for (var i = 0; i < 300; i++) {
      final focal = uniform(4, 2000);
      final crop = uniform(1, 6);
      final aperture = uniform(0.95, 32);
      final pixelPitch = uniform(0.8, 10);
      final desiredTrail = uniform(0.5, 90);
      final latitude = uniform(-90, 90);
      final instant = DateTime.utc(
        2026,
        1,
        1,
      ).add(Duration(minutes: random.nextInt(365 * 3 * 24 * 60)));
      final input = AstronomyInput(
        observerLatitudeDegrees: latitude,
        observerLongitudeDegrees: uniform(-180, 180),
        observerElevationMetres: uniform(0, 4000),
        instantUtc: instant,
        target: CelestialTarget
            .values[random.nextInt(CelestialTarget.values.length)],
        focalLengthMm: focal,
        cropFactor: crop,
        aperture: aperture,
        pixelPitchMicrometres: pixelPitch,
        desiredTrailDegrees: desiredTrail,
        selectedRule: StarShutterRule
            .values[random.nextInt(StarShutterRule.values.length)],
        sharpnessTolerance: StarSharpnessTolerance
            .values[random.nextInt(StarSharpnessTolerance.values.length)],
      );
      final context =
          '${input.target} lat=$latitude focal=$focal N=$aperture '
          'pitch=$pixelPitch instant=$instant';

      final result = calculator.calculate(input);
      if (!result.isUsable) {
        refused++;
        violations.add(
          'rejected ${result.errors.map((e) => e.code).toList()} $context',
        );
        continue;
      }

      final output = result.output!;
      if (output.altitudeDegrees < -90 || output.altitudeDegrees > 90) {
        violations.add('altitude ${output.altitudeDegrees} $context');
      }
      if (output.azimuthDegrees < 0 || output.azimuthDegrees >= 360) {
        violations.add('azimuth ${output.azimuthDegrees} $context');
      }
      if (output.rightAscensionDegrees < 0 ||
          output.rightAscensionDegrees >= 360) {
        violations.add(
          'right ascension ${output.rightAscensionDegrees} $context',
        );
      }
      if (output.declinationDegrees < -90 || output.declinationDegrees > 90) {
        violations.add('declination ${output.declinationDegrees} $context');
      }
      if (output.isAboveHorizon != (output.altitudeDegrees > 0)) {
        violations.add(
          'aboveHorizon ${output.isAboveHorizon} at '
          '${output.altitudeDegrees} degrees $context',
        );
      }

      // The path is what the screen plots: seven samples two hours apart,
      // centred on the instant whose position is reported above.
      if (output.path.length != 7) {
        violations.add('${output.path.length} path samples $context');
      } else {
        final middle = output.path[3];
        if (middle.instantUtc != instant) {
          violations.add('path is not centred on the instant $context');
        }
        expectClose(
          violations,
          'path altitude',
          middle.altitudeDegrees,
          output.altitudeDegrees,
        );
        expectClose(
          violations,
          'path azimuth',
          middle.azimuthDegrees,
          output.azimuthDegrees,
        );
        for (var index = 0; index < output.path.length; index++) {
          final sample = output.path[index];
          if (sample.altitudeDegrees < -90 || sample.altitudeDegrees > 90) {
            violations.add(
              'path[$index] altitude ${sample.altitudeDegrees} $context',
            );
          }
          if (sample.azimuthDegrees < 0 || sample.azimuthDegrees >= 360) {
            violations.add(
              'path[$index] azimuth ${sample.azimuthDegrees} $context',
            );
          }
          if (index > 0 &&
              !sample.instantUtc.isAfter(output.path[index - 1].instantUtc)) {
            violations.add('path samples are not in time order $context');
          }
        }
      }

      // The shutter rules are closed-form, so they are checked against their
      // own arithmetic rather than against a remembered number.
      final rule500 = 500 / (focal * crop);
      final npf = (35 * aperture + 30 * pixelPitch) / focal;
      expectClose(violations, '500 rule', output.rule500Seconds, rule500);
      expectClose(violations, 'NPF rule', output.npfSeconds, npf);

      final multiplier = switch (input.sharpnessTolerance) {
        StarSharpnessTolerance.strict => 0.75,
        StarSharpnessTolerance.balanced => 1.0,
        StarSharpnessTolerance.relaxed => 1.25,
      };
      final base = input.selectedRule == StarShutterRule.rule500
          ? rule500
          : npf;
      expectClose(
        violations,
        'recommended shutter',
        output.recommendedShutterSeconds,
        base * multiplier,
      );

      // Trail time and rotation are reciprocal views of the same sidereal day,
      // so their product has to return the requested trail in seconds without
      // either of them having to name the constant.
      final product =
          output.trailDurationSeconds * output.trailRotationDegreesPerHour;
      expectClose(
        violations,
        'trail duration x rotation',
        product,
        desiredTrail * 3600,
      );

      if (output.trailDurationSeconds <= 0) {
        violations.add(
          'trail duration ${output.trailDurationSeconds} $context',
        );
      }

      // The visibility cycle is a claim about the whole day, and the path
      // spans only twelve hours, so it can falsify the two polar cycles
      // (which hold at every hour) but never the ordinary one: a target
      // that rises at hour one and sets at hour thirteen sits above the
      // horizon for the entire sampled window and still rises and sets.
      final lowest = output.path
          .map((sample) => sample.altitudeDegrees)
          .reduce(math.min);
      final highest = output.path
          .map((sample) => sample.altitudeDegrees)
          .reduce(math.max);
      switch (output.visibilityCycle) {
        case VisibilityCycle.circumpolar:
          if (lowest <= 0) {
            violations.add('circumpolar but dips to $lowest degrees $context');
          }
        case VisibilityCycle.neverRises:
          if (highest >= 0) {
            violations.add(
              'never rises but climbs to $highest degrees $context',
            );
          }
        case VisibilityCycle.risesAndSets:
          break;
      }

      final eventTypes = output.events.map((event) => event.type).toList();
      for (var index = 0; index < output.events.length; index++) {
        if (index > 0 &&
            !output.events[index].instantUtc.isAfter(
              output.events[index - 1].instantUtc,
            )) {
          violations.add('events are not in time order $context');
        }
      }
      if (output.visibilityCycle == VisibilityCycle.neverRises &&
          eventTypes.any(
            (type) =>
                type == CelestialEventType.rise ||
                type == CelestialEventType.set,
          )) {
        violations.add('never rises, yet reports $eventTypes $context');
      }

      final orientation = output.milkyWayOrientationDegrees;
      if (orientation != null) {
        if (input.target != CelestialTarget.milkyWayCore) {
          violations.add('galactic orientation for ${input.target} $context');
        }
        if (orientation < 0 || orientation >= 180) {
          violations.add('orientation $orientation $context');
        }
      } else if (input.target == CelestialTarget.milkyWayCore &&
          latitude.abs() < 80) {
        // The core is the one target whose orientation is reported; it is null
        // only within a tenth of a degree of the zenith or nadir.
        violations.add(
          'no orientation for the galactic core at $latitude $context',
        );
      }
    }

    expect(
      violations.take(5),
      isEmpty,
      reason: '${violations.length} violations',
    );
    expect(
      refused,
      lessThan(300 ~/ 2),
      reason: '$refused of 300 calculations were refused',
    );
  });
}
