import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/features/alignment/domain/alignment_calculator.dart';

void main() {
  const ephemeris = AlignmentSkyEphemeris();

  test('derives geodesic target bearing and distance', () {
    final geometry = TargetGeometry.fromCoordinates(
      observerLatitudeDegrees: 48.8566,
      observerLongitudeDegrees: 2.3522,
      targetLatitudeDegrees: 51.5074,
      targetLongitudeDegrees: -0.1278,
    );
    expect(geometry.bearingDegrees, closeTo(330.0, 0.2));
    expect(geometry.distanceMetres / 1000, closeTo(343.6, 1));
  });

  test('March equinox Sun is near south at Greenwich noon', () {
    final position = ephemeris.position(
      body: AlignmentBody.sun,
      instantUtc: DateTime.utc(2026, 3, 20, 12),
      latitudeDegrees: 51.4779,
      longitudeDegrees: 0,
    );
    expect(position.azimuthDegrees, closeTo(177.5, 1));
    expect(position.altitudeDegrees, closeTo(38.6, 0.6));
  });

  test('search returns ordered solar alignment candidates', () {
    final result = const AlignmentCalculator().search(
      AlignmentSearchInput(
        body: AlignmentBody.sun,
        observerLatitudeDegrees: 51.4779,
        observerLongitudeDegrees: 0,
        observerElevationMetres: 20,
        targetElevationMetres: 820,
        targetDistanceMetres: 1000,
        desiredBearingDegrees: 180,
        angularToleranceDegrees: 2,
        startUtc: DateTime.utc(2026, 3, 20),
        endUtc: DateTime.utc(2026, 3, 21),
      ),
    );
    expect(result.errors, isEmpty);
    expect(result.output!.candidates, isNotEmpty);
    // Absolute anchors, independent of the production list's own order. The
    // search samples every ten minutes, so the best sampled candidate sits up
    // to about half a step away from the optimum; the measured residual for
    // this input is 0.66 degrees, inside the 1.25 degree sampling bound. The
    // desire is 180 true bearing and this file's equinox fixture puts the Sun
    // at 177.5 degrees azimuth at 12:00 UTC, so the best match must still fall
    // near solar noon.
    final best = result.output!.candidates.first;
    expect(best.angularErrorDegrees, lessThan(1.25));
    expect(
      best.instantUtc.difference(DateTime.utc(2026, 3, 20, 12)).inMinutes.abs(),
      lessThan(20),
      reason: 'best candidate should be near the 12:00 UTC equinox fixture',
    );
    expect(
      result.output!.candidates.map((item) => item.angularErrorDegrees),
      orderedEquals(
        [...result.output!.candidates.map((item) => item.angularErrorDegrees)]
          ..sort(),
      ),
    );
  });

  test('target elevation changes desired altitude', () {
    final output = const AlignmentCalculator()
        .search(
          AlignmentSearchInput(
            body: AlignmentBody.moon,
            observerLatitudeDegrees: 45,
            observerLongitudeDegrees: 5,
            observerElevationMetres: 100,
            targetElevationMetres: 200,
            targetDistanceMetres: 1000,
            desiredBearingDegrees: 120,
            angularToleranceDegrees: 180,
            startUtc: DateTime.utc(2026, 8, 21),
            endUtc: DateTime.utc(2026, 8, 21, 12),
          ),
        )
        .output!;
    expect(output.desiredAltitudeDegrees, closeTo(5.71, 0.01));
    expect(output.candidates, isNotEmpty);
  });

  test('searches a full year within the planning performance budget', () {
    final stopwatch = Stopwatch()..start();
    final result = const AlignmentCalculator().search(
      AlignmentSearchInput(
        body: AlignmentBody.sun,
        observerLatitudeDegrees: 48.8566,
        observerLongitudeDegrees: 2.3522,
        observerElevationMetres: 35,
        targetElevationMetres: 335,
        targetDistanceMetres: 1000,
        desiredBearingDegrees: 180,
        angularToleranceDegrees: 5,
        startUtc: DateTime.utc(2026),
        endUtc: DateTime.utc(2026, 12, 31, 23, 59),
      ),
    );
    stopwatch.stop();

    expect(result.errors, isEmpty);
    expect(result.output!.candidates.length, lessThanOrEqualTo(20));
    expect(
      result.output!.candidates.map((item) => item.angularErrorDegrees),
      orderedEquals(
        [...result.output!.candidates.map((item) => item.angularErrorDegrees)]
          ..sort(),
      ),
    );
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
  });

  test('rejects ranges longer than one year', () {
    final result = const AlignmentCalculator().search(
      AlignmentSearchInput(
        body: AlignmentBody.moon,
        observerLatitudeDegrees: 45,
        observerLongitudeDegrees: 5,
        observerElevationMetres: 100,
        targetElevationMetres: 200,
        targetDistanceMetres: 1000,
        desiredBearingDegrees: 120,
        angularToleranceDegrees: 3,
        startUtc: DateTime.utc(2026),
        endUtc: DateTime.utc(2027, 1, 3),
      ),
    );

    expect(result.output, isNull);
    expect(result.errors.single.field, 'dateRange');
  });

  test('validates coordinates, dates, geometry, and tolerance', () {
    final result = const AlignmentCalculator().search(
      AlignmentSearchInput(
        body: AlignmentBody.sun,
        observerLatitudeDegrees: 91,
        observerLongitudeDegrees: 181,
        observerElevationMetres: double.nan,
        targetElevationMetres: 0,
        targetDistanceMetres: 0,
        desiredBearingDegrees: 360,
        angularToleranceDegrees: 0,
        startUtc: DateTime.utc(2026, 2),
        endUtc: DateTime.utc(2026, 1),
      ),
    );
    expect(result.output, isNull);
    expect(result.errors, hasLength(7));
  });

  test('geodesic geometry is correct across the antimeridian', () {
    final geometry = TargetGeometry.fromCoordinates(
      observerLatitudeDegrees: 0,
      observerLongitudeDegrees: 179.9,
      targetLatitudeDegrees: 0,
      targetLongitudeDegrees: -179.9,
    );
    // 0.2 degrees of longitude at the equator, eastward.
    expect(geometry.distanceMetres / 1000, closeTo(22.24, 0.2));
    expect(geometry.bearingDegrees, closeTo(90, 0.5));
  });

  test(
    'a below-sea-level observer is accepted and lowers the target angle',
    () {
      final result = const AlignmentCalculator().search(
        AlignmentSearchInput(
          body: AlignmentBody.sun,
          observerLatitudeDegrees: 31.5,
          observerLongitudeDegrees: 35.5,
          // Dead Sea shore, below sea level, with a target at sea level.
          observerElevationMetres: -430,
          targetElevationMetres: 0,
          targetDistanceMetres: 1000,
          desiredBearingDegrees: 90,
          // A full-circle tolerance guarantees candidates, so the candidate
          // invariants below are actually exercised rather than skipped.
          angularToleranceDegrees: 180,
          startUtc: DateTime.utc(2026, 3, 20),
          endUtc: DateTime.utc(2026, 3, 21),
        ),
      );
      expect(result.errors, isEmpty);
      // The target is 430 m above the observer: atan2(430, 1000) is 23.2717
      // degrees, an absolute closed form for this geometry.
      expect(result.output!.desiredAltitudeDegrees, closeTo(23.27, 0.01));
      expect(result.output!.candidates, isNotEmpty);
      for (final candidate in result.output!.candidates) {
        expect(candidate.altitudeDegrees.isFinite, isTrue);
        expect(candidate.azimuthDegrees.isFinite, isTrue);
        expect(candidate.angularErrorDegrees.isFinite, isTrue);
        expect(candidate.altitudeDegrees, inInclusiveRange(-90, 90));
        expect(candidate.azimuthDegrees, inInclusiveRange(0, 360));
      }
    },
  );
}
