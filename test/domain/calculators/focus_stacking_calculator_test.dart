import 'package:camera_assistant/domain/calculators/focus_stacking_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FocusStackingCalculator', () {
    test('plans multiple frames across a finite subject depth', () {
      final result = FocusStackingCalculator.plan(
        focalLengthMm: 50,
        aperture: 8,
        cocM: 0.00003,
        nearestSubjectDistanceM: 0.5,
        farthestSubjectDistanceM: 0.7,
        overlapRatio: 0.3,
      );

      expect(result.frameLimitReached, isFalse);
      expect(result.coversEntireRange, isTrue);
      expect(result.frameCount, 5);
      expect(result.firstFocusDistanceM, closeTo(0.5226, 0.0002));
      expect(result.lastFocusDistanceM, closeTo(0.7104, 0.0002));
      expect(result.coveredFarM, closeTo(0.7582, 0.0003));
      expect(result.averageFocusStepM, closeTo(0.0469, 0.0005));
    });

    test('collapses to one frame when the first shot covers the range', () {
      final result = FocusStackingCalculator.plan(
        focalLengthMm: 50,
        aperture: 11,
        cocM: 0.00003,
        nearestSubjectDistanceM: 1.5,
        farthestSubjectDistanceM: 1.6,
        overlapRatio: 0.3,
      );

      expect(result.frameLimitReached, isFalse);
      expect(result.frameCount, 1);
      expect(result.coversEntireRange, isTrue);
      expect(result.coveredFarM, greaterThanOrEqualTo(1.6));
    });
  });

  group('MacroFocusStackingCalculator', () {
    test('plans rail steps from focus plane thickness', () {
      final result = MacroFocusStackingCalculator.plan(
        aperture: 2.8,
        cocM: 0.00003,
        magnification: 1.5714,
        subjectDepthM: 0.001,
        overlapRatio: 0.3,
      );

      expect(result.frameCount, 8);
      expect(result.focusPlaneThicknessM, closeTo(0.00017495, 0.0000002));
      expect(result.recommendedRailStepM, closeTo(0.00012246, 0.0000002));
      expect(result.shots.last.endOffsetM, closeTo(0.001, 0.0000002));
    });
  });
}
