import 'package:camera_assistant/domain/calculators/astro_calculator.dart';
import 'package:camera_assistant/domain/models/sensor_preset.dart';

enum AstroToolMode { shutter, framing }

class AstroInput {
  const AstroInput({
    required this.focalLengthMm,
    required this.sensor,
    required this.rule,
    required this.target,
    required this.orientation,
  });

  final double? focalLengthMm;
  final SensorPreset sensor;
  final AstroShutterRule rule;
  final AstroFramingTarget target;
  final AstroFramingOrientation orientation;
}

sealed class AstroCalculationState {
  const AstroCalculationState();
}

class AstroCalculationSuccess extends AstroCalculationState {
  const AstroCalculationSuccess({
    required this.shutterResult,
    required this.framingResult,
  });

  final AstroCalculatorResult shutterResult;
  final AstroFramingResult framingResult;
}

class AstroCalculationError extends AstroCalculationState {
  const AstroCalculationError(this.message);

  final String? message;
}
