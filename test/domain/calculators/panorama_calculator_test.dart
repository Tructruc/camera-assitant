import 'package:camera_assistant/domain/calculators/panorama_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates single-frame coverage when target fits one frame', () {
    final result = PanoramaCalculator.calculate(
      focalLengthMm: 24,
      sensorWidthMm: 36,
      sensorHeightMm: 24,
      orientation: PanoramaOrientation.landscape,
      targetHorizontalFovDeg: 60,
      targetVerticalFovDeg: 35,
      overlapPercent: 30,
    );

    expect(result.horizontalFrames, 1);
    expect(result.verticalFrames, 1);
    expect(result.totalFrames, 1);
    expect(result.frameHorizontalFovDeg, closeTo(73.7, 0.2));
    expect(result.frameVerticalFovDeg, closeTo(53.1, 0.2));
  });

  test('calculates multi-row multi-column panorama', () {
    final result = PanoramaCalculator.calculate(
      focalLengthMm: 50,
      sensorWidthMm: 36,
      sensorHeightMm: 24,
      orientation: PanoramaOrientation.portrait,
      targetHorizontalFovDeg: 120,
      targetVerticalFovDeg: 60,
      overlapPercent: 30,
    );

    expect(result.horizontalFrames, 6);
    expect(result.verticalFrames, 2);
    expect(result.totalFrames, 12);
    expect(result.horizontalAdvanceDeg, closeTo(18.9, 0.2));
    expect(result.verticalAdvanceDeg, closeTo(27.7, 0.2));
    expect(result.stitchedHorizontalFovDeg, greaterThanOrEqualTo(120));
    expect(result.stitchedVerticalFovDeg, greaterThanOrEqualTo(60));
  });
}
