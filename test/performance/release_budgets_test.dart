import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/data/database/app_database.dart';
import 'package:photography_assistant/features/alignment/domain/alignment_calculator.dart';
import 'package:photography_assistant/features/depth_of_field/domain/depth_of_field_calculator.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';
import 'package:photography_assistant/features/equipment/domain/equipment.dart';
import 'package:photography_assistant/features/exposure_comparison/domain/exposure_calculator.dart';
import 'package:photography_assistant/features/long_exposure/domain/long_exposure_calculator.dart';

void main() {
  test('one-year alignment search remains below five seconds', () {
    final watch = Stopwatch()..start();
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
    watch.stop();

    expect(result.errors, isEmpty);
    expect(result.output!.candidates.length, lessThanOrEqualTo(20));
    expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
    // Visible in CI logs and copied into the release evidence document.
    // ignore: avoid_print
    print('alignment_one_year_ms=${watch.elapsedMilliseconds}');
  });

  test('calculator p95 remains below the 100 ms field budget', () {
    final samples = <int>[];
    for (var index = 0; index < 1000; index++) {
      final watch = Stopwatch()..start();
      const DepthOfFieldCalculator().calculate(
        const DepthOfFieldInput(
          focalLengthMm: 50,
          aperture: 8,
          focusDistanceMm: 10000,
          circleOfConfusionMm: 0.03,
        ),
      );
      const ExposureCalculator().calculate(
        const ExposureComparisonInput(
          baseline: ExposureTriple(aperture: 4, timeSeconds: 0.008, iso: 100),
          candidate: ExposureTriple(
            aperture: 5.6,
            timeSeconds: 0.016,
            iso: 100,
          ),
        ),
      );
      const LongExposureCalculator().calculate(
        const LongExposureInput(
          baseTimeSeconds: 1 / 30,
          filters: <NdInput>[NdInput.stops(3), NdInput.stops(7)],
        ),
      );
      watch.stop();
      samples.add(watch.elapsedMicroseconds);
    }
    samples.sort();
    final p95Microseconds = samples[(samples.length * 0.95).floor()];
    expect(p95Microseconds, lessThan(100000));
    // Visible in CI logs and copied into the release evidence document.
    // ignore: avoid_print
    print('calculator_bundle_p95_us=$p95Microseconds');
  });

  test('1,000-item inventory readiness remains below 500 ms', () async {
    final database = AppDatabase.inMemory();
    addTearDown(database.close);
    final repository = DriftEquipmentRepository(database);
    final now = DateTime.utc(2026, 8, 21);
    await database.batch((batch) {
      for (var index = 0; index < 1000; index++) {
        batch.customStatement(
          '''INSERT INTO camera_bodies
             (id, name, normalized_name, sensor_width_mm, sensor_height_mm,
              source_type, created_at, updated_at)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
          <Object>[
            'performance-camera-$index',
            'Performance Camera $index',
            'performance camera ${index.toString().padLeft(4, '0')}',
            36.0,
            24.0,
            EquipmentSource.user.name,
            now.millisecondsSinceEpoch,
            now.millisecondsSinceEpoch,
          ],
        );
      }
    });

    final samples = <int>[];
    for (var index = 0; index < 20; index++) {
      final watch = Stopwatch()..start();
      final cameras = await repository.listCameras();
      watch.stop();
      expect(cameras, hasLength(1000));
      samples.add(watch.elapsedMicroseconds);
    }
    samples.sort();
    final p95Microseconds = samples[(samples.length * 0.95).floor()];
    expect(p95Microseconds, lessThan(500000));
    // ignore: avoid_print
    print('inventory_1000_p95_us=$p95Microseconds');
  });
}
