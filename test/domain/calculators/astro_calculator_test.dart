import 'package:camera_assistant/domain/calculators/astro_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('500 rule on full frame keeps focal length unchanged', () {
    final result = AstroCalculator.calculateMaxShutter(
      focalLengthMm: 20,
      sensorWidthMm: 36,
      sensorHeightMm: 24,
      rule: AstroShutterRule.rule500,
    );

    expect(result.cropFactor, closeTo(1.0, 0.0001));
    expect(result.equivalentFocalLengthMm, closeTo(20.0, 0.0001));
    expect(result.maxShutterSeconds, closeTo(25.0, 0.0001));
  });

  test('400 rule shortens shutter on smaller sensors', () {
    final result = AstroCalculator.calculateMaxShutter(
      focalLengthMm: 20,
      sensorWidthMm: 22.3,
      sensorHeightMm: 14.9,
      rule: AstroShutterRule.rule400,
    );

    expect(result.cropFactor, closeTo(1.61, 0.01));
    expect(result.equivalentFocalLengthMm, closeTo(32.28, 0.1));
    expect(result.maxShutterSeconds, closeTo(12.39, 0.1));
  });
}
