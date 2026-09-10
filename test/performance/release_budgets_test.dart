import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/data/database/app_database.dart';
import 'package:photography_assistant/features/alignment/domain/alignment_calculator.dart';
import 'package:photography_assistant/features/astronomy/domain/astronomy_calculator.dart';
import 'package:photography_assistant/features/depth_of_field/domain/depth_of_field_calculator.dart';
import 'package:photography_assistant/features/equipment/data/drift_equipment_repository.dart';
import 'package:photography_assistant/features/equipment/domain/equipment.dart';
import 'package:photography_assistant/features/exposure_comparison/domain/exposure_calculator.dart';
import 'package:photography_assistant/features/flash_exposure/domain/flash_exposure_calculator.dart';
import 'package:photography_assistant/features/long_exposure/domain/long_exposure_calculator.dart';
import 'package:photography_assistant/features/macro/domain/macro_calculator.dart';
import 'package:photography_assistant/features/optics/domain/optics_calculators.dart';
import 'package:photography_assistant/features/panorama/domain/panorama_calculator.dart';
import 'package:photography_assistant/features/timelapse/domain/timelapse_calculator.dart';

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

  test('every released calculator stays inside the field budget', () {
    final samples = <int>[];
    for (var index = 0; index < 200; index++) {
      final watch = Stopwatch()..start();
      const FieldOfViewCalculator().calculate(
        const FieldOfViewInput(
          sensorWidthMm: 36,
          sensorHeightMm: 24,
          focalLengthMm: 50,
          distanceMm: 10000,
        ),
      );
      const DiffractionCalculator().calculate(
        const DiffractionInput(
          aperture: 8,
          wavelengthNm: 550,
          pixelPitchMicrometres: 4,
        ),
      );
      const FocusStackCalculator().calculate(
        const FocusStackInput(
          focalLengthMm: 100,
          aperture: 8,
          circleOfConfusionMm: 0.03,
          nearDistanceMm: 500,
          farDistanceMm: 1000,
          overlapPercent: 20,
        ),
      );
      const MacroCalculator().calculate(
        const MacroInput.extensionTube(
          focalLengthMm: 50,
          extensionLengthMm: 25,
          nativeMagnification: 0.2,
          nominalAperture: 8,
          sensorWidthMm: 36,
        ),
      );
      const PanoramaCalculator().calculate(
        const PanoramaInput(
          sensorWidthMm: 36,
          sensorHeightMm: 24,
          focalLengthMm: 50,
          orientation: CameraOrientation.landscape,
          horizontalBoundsDegrees: 90,
          verticalBoundsDegrees: 45,
          horizontalOverlapPercent: 30,
          verticalOverlapPercent: 30,
        ),
      );
      const FlashExposureCalculator().calculate(
        const FlashExposureInput(
          guideNumberIso100Metres: 40,
          iso: 100,
          powerFraction: 1,
          subjectDistanceMetres: 5,
        ),
      );
      const TimelapseCalculator().calculate(
        const TimelapseInput(
          intervalSeconds: 10,
          captureDurationSeconds: 3600,
          playbackFps: 30,
          megabytesPerFrame: 25,
          startExposureSeconds: 1,
          endExposureSeconds: 4,
        ),
      );
      const AstronomyCalculator().calculate(
        AstronomyInput(
          observerLatitudeDegrees: 51.4779,
          observerLongitudeDegrees: 0,
          instantUtc: DateTime.utc(2026, 1, 15, 22),
          target: CelestialTarget.sirius,
          focalLengthMm: 24,
          cropFactor: 1,
          aperture: 2.8,
          pixelPitchMicrometres: 5,
          desiredTrailDegrees: 10,
        ),
      );
      watch.stop();
      samples.add(watch.elapsedMicroseconds);
    }
    samples.sort();
    final p95Microseconds = samples[(samples.length * 0.95).floor()];
    expect(p95Microseconds, lessThan(100000));
    // The device half of SC-009 (cold launch, scrolling, permission prompts on
    // representative hardware) is not measurable on the test host; see
    // validation/android.md for the device-side evidence policy.
    // ignore: avoid_print
    print('expanded_calculator_p95_us=$p95Microseconds');
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
