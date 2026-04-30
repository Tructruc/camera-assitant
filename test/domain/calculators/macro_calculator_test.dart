import 'package:camera_assistant/domain/calculators/macro_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MacroCalculator', () {
    test('estimates native magnification from sensor distance', () {
      final magnification =
          MacroCalculator.estimateMagnificationFromSensorDistance(
        focalLengthMm: 50,
        sensorToSubjectDistanceMm: 450,
      );

      expect(magnification, closeTo(0.1459, 0.0001));
    });

    test('calculates extension tube focus and light loss range', () {
      final result = MacroCalculator.calculateExtensionTube(
        focalLengthMm: 50,
        aperture: 2.8,
        cocM: 0.00003,
        minimumFocusDistanceM: 0.45,
        extensionLengthMm: 25,
      );

      expect(result.addedMagnification, closeTo(0.5, 0.0001));
      expect(result.minimumMagnification, closeTo(0.5, 0.0001));
      expect(result.maximumMagnification, closeTo(0.6459, 0.0001));
      expect(result.closestFocusDistanceM, closeTo(0.2097, 0.0002));
      expect(result.farthestFocusDistanceM, closeTo(0.2250, 0.0001));
      expect(result.effectiveApertureAtClosestFocus, closeTo(4.6085, 0.0002));
      expect(result.lightLossStopsAtClosestFocus, closeTo(1.4377, 0.0003));
      expect(
        result.focusPlaneThicknessAtFarthestFocusM,
        closeTo(0.001008, 0.0000001),
      );
      expect(
        result.focusPlaneThicknessAtClosestFocusM,
        closeTo(0.0006628, 0.0000002),
      );
    });

    test('calculates reverse lens magnification and exposure factor', () {
      final result = MacroCalculator.calculateReverseLens(
        focalLengthMm: 28,
        aperture: 2.8,
        cocM: 0.00003,
        extensionBehindLensMm: 44,
      );

      expect(result.magnification, closeTo(1.5714, 0.0001));
      expect(result.effectiveAperture, closeTo(7.2, 0.0001));
      expect(result.lightLossStops, closeTo(2.7251, 0.0006));
      expect(result.exposureFactor, closeTo(6.6122, 0.0002));
      expect(result.subjectDistanceFromLensPlaneM, closeTo(0.0458, 0.0002));
      expect(result.subjectDistanceFromSensorPlaneM, closeTo(0.1178, 0.0002));
      expect(result.focusPlaneThicknessM, closeTo(0.00017494, 0.0000001));
    });

    test('calculates dual lens macro magnification and working distance', () {
      final result = MacroCalculator.calculateDualLensMacro(
        takingLensFocalLengthMm: 100,
        takingLensAperture: 5.6,
        cocM: 0.00003,
        frontLensFocalLengthMm: 50,
      );

      expect(result.magnification, closeTo(2.0, 0.0001));
      expect(result.effectiveAperture, closeTo(16.8, 0.0001));
      expect(result.lightLossStops, closeTo(3.1699, 0.0001));
      expect(result.exposureFactor, closeTo(9.0, 0.0001));
      expect(result.workingDistanceFromFrontLensM, closeTo(0.05, 0.0001));
      expect(result.focusPlaneThicknessM, closeTo(0.000252, 0.0000001));
    });
  });
}
