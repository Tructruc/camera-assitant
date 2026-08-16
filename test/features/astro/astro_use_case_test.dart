import 'package:camera_assistant/domain/calculators/astro_calculator.dart';
import 'package:camera_assistant/domain/models/sensor_preset.dart';
import 'package:camera_assistant/features/astro/astro_state.dart';
import 'package:camera_assistant/features/astro/astro_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sensor = SensorPreset(
    id: 'full_frame',
    label: 'Full Frame',
    cocMm: 0.030,
    widthMm: 36,
    heightMm: 24,
  );

  const useCase = AstroUseCase();

  test('returns hidden live error for invalid focal length', () {
    final result = useCase.calculate(
      const AstroInput(
        focalLengthMm: null,
        sensor: sensor,
        rule: AstroShutterRule.rule400,
        target: AstroFramingTarget.moon,
        orientation: AstroFramingOrientation.landscape,
      ),
      live: true,
    );

    expect(result, isA<AstroCalculationError>());
    expect((result as AstroCalculationError).message, isNull);
  });

  test('returns explicit error when focal length is invalid', () {
    final result = useCase.calculate(
      const AstroInput(
        focalLengthMm: 0,
        sensor: sensor,
        rule: AstroShutterRule.rule400,
        target: AstroFramingTarget.moon,
        orientation: AstroFramingOrientation.landscape,
      ),
    );

    expect(result, isA<AstroCalculationError>());
    expect(
      (result as AstroCalculationError).message,
      'Enter a valid focal length.',
    );
  });

  test('calculates shutter and framing values from valid input', () {
    final result = useCase.calculate(
      const AstroInput(
        focalLengthMm: 50,
        sensor: sensor,
        rule: AstroShutterRule.rule400,
        target: AstroFramingTarget.moon,
        orientation: AstroFramingOrientation.landscape,
      ),
    );

    expect(result, isA<AstroCalculationSuccess>());
    final success = result as AstroCalculationSuccess;
    expect(success.shutterResult.maxShutterSeconds, closeTo(8.0, 0.0001));
    expect(success.framingResult.horizontalFovDeg, closeTo(39.6, 0.1));
    expect(success.framingResult.frameWidthCoverage, greaterThan(0));
  });
}
