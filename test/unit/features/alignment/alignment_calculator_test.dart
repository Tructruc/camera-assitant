import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/features/alignment/domain/alignment_calculator.dart';

void main() {
  const ephemeris = SolarLunarEphemeris();

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
    expect(result.output!.candidates.first.angularErrorDegrees, lessThan(1));
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
}
