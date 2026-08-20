import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/domain/calculation_result.dart';
import 'package:photography_assistant/features/optics/domain/optics_calculators.dart';

void main() {
  group('field of view', () {
    test('matches a 36 × 24 mm sensor with a 50 mm rectilinear lens', () {
      final result = const FieldOfViewCalculator().calculate(
        const FieldOfViewInput(
          sensorWidthMm: 36,
          sensorHeightMm: 24,
          focalLengthMm: 50,
          distanceMm: 10000,
        ),
      );
      expect(result.output!.horizontalDegrees, closeTo(39.5978, 0.0001));
      expect(result.output!.verticalDegrees, closeTo(26.9915, 0.0001));
      expect(result.output!.sceneWidthMm, closeTo(7200, 0.001));
      expect(result.output!.sceneHeightMm, closeTo(4800, 0.001));
    });

    test('rejects non-physical dimensions', () {
      final result = const FieldOfViewCalculator().calculate(
        const FieldOfViewInput(
          sensorWidthMm: 0,
          sensorHeightMm: 24,
          focalLengthMm: double.nan,
          distanceMm: -1,
        ),
      );
      expect(result.status, CalculationStatus.invalid);
      expect(result.errors.map((error) => error.field), [
        'sensorWidthMm',
        'focalLengthMm',
        'distanceMm',
      ]);
    });
  });

  group('diffraction', () {
    test('uses the first Airy minimum diameter', () {
      final result = const DiffractionCalculator().calculate(
        const DiffractionInput(
          aperture: 8,
          wavelengthNm: 550,
          pixelPitchMicrometres: 4,
        ),
      );
      expect(result.output!.airyDiskMicrometres, closeTo(10.736, 0.0001));
      expect(result.output!.airyDiskPixels, closeTo(2.684, 0.0001));
      expect(result.status, CalculationStatus.validWithWarning);
    });

    test('rejects invalid wavelength and pixel pitch', () {
      final result = const DiffractionCalculator().calculate(
        const DiffractionInput(
          aperture: 8,
          wavelengthNm: double.infinity,
          pixelPitchMicrometres: 0,
        ),
      );
      expect(result.errors.map((error) => error.field), [
        'wavelengthNm',
        'pixelPitchMicrometres',
      ]);
    });
  });

  group('focus stacking', () {
    test('returns ordered positions covering the requested range', () {
      final result = const FocusStackCalculator().calculate(
        const FocusStackInput(
          focalLengthMm: 100,
          aperture: 8,
          circleOfConfusionMm: 0.03,
          nearDistanceMm: 500,
          farDistanceMm: 1000,
          overlapPercent: 20,
        ),
      );
      final positions = result.output!.focusDistancesMm;
      expect(positions.first, 500);
      expect(positions.last, 1000);
      expect(positions.length, greaterThan(2));
      for (var index = 1; index < positions.length; index++) {
        expect(positions[index], greaterThan(positions[index - 1]));
      }
    });

    test('validates range, optical distance, and overlap', () {
      final result = const FocusStackCalculator().calculate(
        const FocusStackInput(
          focalLengthMm: 100,
          aperture: 8,
          circleOfConfusionMm: 0.03,
          nearDistanceMm: 90,
          farDistanceMm: 80,
          overlapPercent: 100,
        ),
      );
      expect(result.status, CalculationStatus.invalid);
      expect(
        result.errors.map((error) => error.field),
        containsAll(['farDistanceMm', 'overlapPercent', 'nearDistanceMm']),
      );
    });
  });
}
