import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/features/alignment/domain/alignment_calculator.dart';

/// Randomized property sweep over the alignment search.
///
/// The alignment planner is the calculator where a wrong answer is hardest to
/// notice: it returns instants, and a photographer drives somewhere to be there
/// at one. So the sweep checks each answer against the definition of the search
/// itself, using only what the output publishes: the geometry of the target it
/// reports, the error it reports for each candidate recomputed from that
/// candidate's own bearing and altitude, the claim that the candidate is a
/// local minimum of that error (re-evaluated ten minutes either side through
/// the same public ephemeris the search used), that the list is ranked best
/// first and that nothing outside the tolerance is ever offered.
void main() {
  final random = math.Random(20260926);
  const calculator = AlignmentCalculator();
  const step = Duration(minutes: 10);

  double uniform(double min, double max) =>
      min + random.nextDouble() * (max - min);

  double normalized(double value) {
    final wrapped = value % 360;
    return wrapped < 0 ? wrapped + 360 : wrapped;
  }

  double signedDegrees(double value) {
    final wrapped = normalized(value);
    return wrapped > 180 ? wrapped - 360 : wrapped;
  }

  double errorOf(
    double azimuthDegrees,
    double altitudeDegrees,
    double desiredBearingDegrees,
    double desiredAltitudeDegrees,
  ) {
    final azimuthError =
        signedDegrees(azimuthDegrees - desiredBearingDegrees) *
        math.cos(desiredAltitudeDegrees * math.pi / 180);
    final altitudeError = altitudeDegrees - desiredAltitudeDegrees;
    return math.sqrt(
      azimuthError * azimuthError + altitudeError * altitudeError,
    );
  }

  test('alignment answers match the geometry they are derived from', () {
    final violations = <String>[];
    var refused = 0;
    var candidates = 0;

    for (var i = 0; i < 150; i++) {
      final start = DateTime.utc(
        2026,
        1 + random.nextInt(12),
        1 + random.nextInt(28),
      ).add(Duration(minutes: random.nextInt(1440)));
      final end = start.add(Duration(minutes: 60 + random.nextInt(2880)));
      final input = AlignmentSearchInput(
        body: AlignmentBody.values[random.nextInt(AlignmentBody.values.length)],
        observerLatitudeDegrees: uniform(-66, 66),
        observerLongitudeDegrees: uniform(-180, 180),
        observerElevationMetres: uniform(0, 4000),
        targetElevationMetres: uniform(0, 4000),
        targetDistanceMetres: uniform(10, 50000),
        desiredBearingDegrees: uniform(0, 359.99),
        angularToleranceDegrees: uniform(0.01, 180),
        startUtc: start,
        endUtc: end,
      );
      final context =
          'body=${input.body} lat=${input.observerLatitudeDegrees} '
          'lon=${input.observerLongitudeDegrees} bearing=${input.desiredBearingDegrees} '
          'tolerance=${input.angularToleranceDegrees} window=$start..$end';

      final result = calculator.search(input);
      if (!result.isUsable) {
        refused++;
        violations.add(
          'rejected ${result.errors.map((e) => e.code).toList()} $context',
        );
        continue;
      }

      final output = result.output!;
      final expectedAltitude =
          math.atan2(
            input.targetElevationMetres - input.observerElevationMetres,
            input.targetDistanceMetres,
          ) *
          180 /
          math.pi;

      if (!output.desiredAltitudeDegrees.isFinite) {
        violations.add(
          'desired altitude ${output.desiredAltitudeDegrees} $context',
        );
      } else if ((output.desiredAltitudeDegrees - expectedAltitude).abs() >
          1e-9) {
        violations.add(
          'desired altitude ${output.desiredAltitudeDegrees}, geometry says '
          '$expectedAltitude $context',
        );
      }

      if (output.candidates.length > 20) {
        violations.add(
          '${output.candidates.length} candidates offered $context',
        );
      }

      // The list is ranked by how close the alignment is, best first - not by
      // time - and every entry has to be within the tolerance the search was
      // given, so a photographer reading down the list sees the best times.
      var previousError = 0.0;
      for (final candidate in output.candidates) {
        candidates++;
        final where = 'candidate at ${candidate.instantUtc} $context';

        if (candidate.instantUtc.isBefore(start) ||
            candidate.instantUtc.isAfter(end)) {
          violations.add('$where is outside the requested window');
        }
        if (candidate.angularErrorDegrees < previousError - 1e-12) {
          violations.add('candidates are not ranked best first $context');
        }
        previousError = candidate.angularErrorDegrees;
        if (candidate.angularErrorDegrees >
            input.angularToleranceDegrees + 1e-9) {
          violations.add(
            'error ${candidate.angularErrorDegrees} beyond the '
            '${input.angularToleranceDegrees} degree tolerance $where',
          );
        }

        if (!candidate.angularErrorDegrees.isFinite ||
            candidate.angularErrorDegrees < 0) {
          violations.add('error ${candidate.angularErrorDegrees} $where');
          continue;
        }
        if (normalized(candidate.azimuthDegrees) != candidate.azimuthDegrees) {
          violations.add(
            'azimuth ${candidate.azimuthDegrees} out of range $where',
          );
        }
        if (candidate.altitudeDegrees < -90 || candidate.altitudeDegrees > 90) {
          violations.add(
            'altitude ${candidate.altitudeDegrees} out of range $where',
          );
        }
        if (candidate.aboveHorizon != (candidate.altitudeDegrees >= 0)) {
          violations.add(
            'aboveHorizon ${candidate.aboveHorizon} at '
            '${candidate.altitudeDegrees} degrees $where',
          );
        }

        // The error the user sees must be the error of the position beside it.
        final recomputed = errorOf(
          candidate.azimuthDegrees,
          candidate.altitudeDegrees,
          input.desiredBearingDegrees,
          output.desiredAltitudeDegrees,
        );
        if ((recomputed - candidate.angularErrorDegrees).abs() > 1e-9) {
          violations.add(
            'error ${candidate.angularErrorDegrees} but its own position gives '
            '$recomputed $where',
          );
        }

        // A candidate is offered as a local minimum: ten minutes either side
        // must be worse, or the app is sending the photographer at the wrong
        // time.
        for (final offset in <Duration>[-step, step]) {
          final neighbourInstant = candidate.instantUtc.add(offset);
          // The search cannot see outside the window it was given, so a
          // candidate sitting on either edge is a minimum by construction:
          // only the interior answers can be held to the claim.
          if (neighbourInstant.isBefore(start) ||
              neighbourInstant.isAfter(end)) {
            continue;
          }
          final neighbour = calculator.ephemeris.position(
            body: input.body,
            instantUtc: neighbourInstant,
            latitudeDegrees: input.observerLatitudeDegrees,
            longitudeDegrees: input.observerLongitudeDegrees,
          );
          final neighbourError = errorOf(
            neighbour.azimuthDegrees,
            neighbour.altitudeDegrees,
            input.desiredBearingDegrees,
            output.desiredAltitudeDegrees,
          );
          if (neighbourError < candidate.angularErrorDegrees - 1e-9) {
            violations.add(
              'not a minimum: ${offset.inMinutes} minutes away the error is '
              '$neighbourError against ${candidate.angularErrorDegrees} $where',
            );
          }
        }
      }
    }

    expect(
      violations.take(5),
      isEmpty,
      reason: '${violations.length} violations',
    );
    expect(
      refused,
      lessThan(150 ~/ 2),
      reason: '$refused of 150 searches were refused',
    );
    expect(
      candidates,
      greaterThan(0),
      reason: 'no candidate was ever produced',
    );
  });

  test('a tolerance nothing can meet yields no candidates', () {
    final start = DateTime.utc(2026, 6, 1);
    final output = calculator
        .search(
          AlignmentSearchInput(
            body: AlignmentBody.sun,
            observerLatitudeDegrees: 48.85,
            observerLongitudeDegrees: 2.35,
            observerElevationMetres: 35,
            targetElevationMetres: 35,
            targetDistanceMetres: 1000,
            desiredBearingDegrees: 0,
            angularToleranceDegrees: 0.01,
            startUtc: start,
            endUtc: start.add(const Duration(hours: 6)),
          ),
        )
        .output!;

    // The sun never sits dead north from Paris, so a search that insists on a
    // hundredth of a degree has to come back empty rather than invent a time.
    expect(output.candidates, isEmpty);
    expect(output.sampleMinutes, 10);
  });
}
