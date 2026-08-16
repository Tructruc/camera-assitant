import 'package:camera_assistant/domain/calculators/astro_calculator.dart';
import 'package:camera_assistant/features/astro/astro_state.dart';

class AstroUseCase {
  const AstroUseCase();

  AstroCalculationState calculate(
    AstroInput input, {
    bool live = false,
  }) {
    final focalLengthMm = input.focalLengthMm;
    if (focalLengthMm == null || focalLengthMm <= 0) {
      return AstroCalculationError(live ? null : 'Enter a valid focal length.');
    }

    final shutterResult = AstroCalculator.calculateMaxShutter(
      focalLengthMm: focalLengthMm,
      sensorWidthMm: input.sensor.widthMm,
      sensorHeightMm: input.sensor.heightMm,
      rule: input.rule,
    );

    final framingResult = AstroCalculator.calculateFraming(
      focalLengthMm: focalLengthMm,
      sensorWidthMm: input.sensor.widthMm,
      sensorHeightMm: input.sensor.heightMm,
      target: input.target,
      orientation: input.orientation,
    );

    return AstroCalculationSuccess(
      shutterResult: shutterResult,
      framingResult: framingResult,
    );
  }
}
