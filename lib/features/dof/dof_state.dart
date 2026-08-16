import 'package:camera_assistant/domain/models/lens.dart';
import 'package:camera_assistant/domain/models/sensor_preset.dart';

class DofInput {
  const DofInput({
    required this.focalLengthMm,
    required this.aperture,
    required this.subjectDistanceM,
    required this.sensor,
    this.lens,
  });

  final double? focalLengthMm;
  final double? aperture;
  final double? subjectDistanceM;
  final SensorPreset sensor;
  final Lens? lens;
}

class DofResult {
  const DofResult({
    required this.hyperfocalM,
    required this.nearLimitM,
    required this.subjectDistanceM,
    required this.farLimitM,
    required this.totalDofM,
  });

  final double hyperfocalM;
  final double nearLimitM;
  final double subjectDistanceM;
  final double? farLimitM;
  final double? totalDofM;
}

sealed class DofCalculationState {
  const DofCalculationState();
}

class DofCalculationSuccess extends DofCalculationState {
  const DofCalculationSuccess(this.result);

  final DofResult result;
}

class DofCalculationError extends DofCalculationState {
  const DofCalculationError(this.message);

  final String? message;
}
