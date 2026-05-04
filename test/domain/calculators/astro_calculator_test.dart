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

  test('moon framing reports field of view and sensor coverage', () {
    final result = AstroCalculator.calculateFraming(
      focalLengthMm: 400,
      sensorWidthMm: 36,
      sensorHeightMm: 24,
      target: AstroFramingTarget.moon,
    );

    expect(result.horizontalFovDeg, closeTo(5.15, 0.01));
    expect(result.verticalFovDeg, closeTo(3.44, 0.01));
    expect(result.objectImageDiameterMm, closeTo(3.63, 0.01));
    expect(result.frameWidthCoverage, closeTo(0.1008, 0.001));
  });

  test('portrait framing swaps width and height fields', () {
    final result = AstroCalculator.calculateFraming(
      focalLengthMm: 400,
      sensorWidthMm: 36,
      sensorHeightMm: 24,
      target: AstroFramingTarget.sun,
      orientation: AstroFramingOrientation.portrait,
    );

    expect(result.frameWidthMm, closeTo(24, 0.001));
    expect(result.frameHeightMm, closeTo(36, 0.001));
    expect(result.horizontalFovDeg, closeTo(3.44, 0.01));
    expect(result.verticalFovDeg, closeTo(5.15, 0.01));
  });

  test('star framing keeps target size unresolved while narrowing field', () {
    final result = AstroCalculator.calculateFraming(
      focalLengthMm: 800,
      sensorWidthMm: 36,
      sensorHeightMm: 24,
      target: AstroFramingTarget.star,
    );

    expect(result.objectImageDiameterMm, closeTo(0.0, 0.000001));
    expect(result.horizontalFovDeg, closeTo(2.58, 0.01));
    expect(result.relativeMagnificationTo50mm, closeTo(16.0, 0.001));
  });
}
