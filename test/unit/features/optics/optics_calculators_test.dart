import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/domain/calculation_result.dart';
import 'package:photography_assistant/core/domain/validation/validation.dart';
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
      expect(result.output, isNull);
      expect(result.errors, const [
        ValidationError(
          field: 'sensorWidthMm',
          code: 'positive_finite_required',
          messageKey: 'optics.error.positiveFinite.sensorWidthMm',
        ),
        ValidationError(
          field: 'focalLengthMm',
          code: 'positive_finite_required',
          messageKey: 'optics.error.positiveFinite.focalLengthMm',
        ),
        ValidationError(
          field: 'distanceMm',
          code: 'positive_finite_required',
          messageKey: 'optics.error.positiveFinite.distanceMm',
        ),
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
      expect(result.status, CalculationStatus.invalid);
      expect(result.output, isNull);
      expect(result.errors, const [
        ValidationError(
          field: 'wavelengthNm',
          code: 'positive_finite_required',
          messageKey: 'optics.error.positiveFinite.wavelengthNm',
        ),
        ValidationError(
          field: 'pixelPitchMicrometres',
          code: 'positive_finite_required',
          messageKey: 'optics.error.positiveFinite.pixelPitchMicrometres',
        ),
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
      // Hyperfocal is 41766.66666666667 mm; with 20% overlap the thin-lens
      // loop needs 61 steps to cover 500 mm -> 1000 mm, plus the pinned far end.
      expect(positions, hasLength(62));
      expect(positions.first, 500.0);
      expect(positions.last, 1000.0);
      expect(positions[1], closeTo(503.87722132471725, 1e-6));
      expect(positions[2], closeTo(507.8227525846824, 1e-6));
      expect(positions[3], closeTo(511.83840892668724, 1e-6));
      expect(positions[4], closeTo(515.9260704172258, 1e-6));
      expect(positions[5], closeTo(520.0876849723631, 1e-6));
      for (var index = 1; index < positions.length; index++) {
        expect(positions[index], greaterThan(positions[index - 1]));
      }
      expect(positions, everyElement(inInclusiveRange(500.0, 1000.0)));
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
      expect(result.output, isNull);
      expect(result.errors, const [
        ValidationError(
          field: 'farDistanceMm',
          code: 'greater_than_near',
          messageKey: 'focusStack.error.farDistance',
        ),
        ValidationError(
          field: 'overlapPercent',
          code: 'range',
          messageKey: 'focusStack.error.overlap',
        ),
        ValidationError(
          field: 'nearDistanceMm',
          code: 'not_beyond_focal_length',
          messageKey: 'focusStack.error.nearDistance',
        ),
      ]);
    });
  });
}
