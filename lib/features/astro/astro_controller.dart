import 'package:camera_assistant/core/parsing/number_parser.dart';
import 'package:camera_assistant/domain/calculators/astro_calculator.dart';
import 'package:camera_assistant/domain/models/lens.dart';
import 'package:camera_assistant/domain/models/sensor_preset.dart';
import 'package:camera_assistant/features/astro/astro_state.dart';
import 'package:camera_assistant/features/astro/astro_use_case.dart';

class AstroController {
  const AstroController({
    this.useCase = const AstroUseCase(),
  });

  final AstroUseCase useCase;

  AstroCalculationState calculateFromForm({
    required String focalLengthText,
    required SensorPreset sensor,
    required AstroShutterRule rule,
    required AstroFramingTarget target,
    required AstroFramingOrientation orientation,
    bool live = false,
  }) {
    return useCase.calculate(
      AstroInput(
        focalLengthMm: parseDouble(focalLengthText),
        sensor: sensor,
        rule: rule,
        target: target,
        orientation: orientation,
      ),
      live: live,
    );
  }

  String focalFromSelectedLens(Lens lens) {
    return _formatFocal(lens.minFocalLengthMm);
  }

  String clampAndFormatFocalForLens(Lens lens, double value) {
    final focal = value.clamp(lens.minFocalLengthMm, lens.maxFocalLengthMm);
    return _formatFocal(focal);
  }

  String _formatFocal(double value) {
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
  }
}
