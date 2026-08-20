/// Deterministic calculators for framing, diffraction, and focus-stack planning.
library;

import 'dart:math' as math;

import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/validation/validation.dart';

final class FieldOfViewInput {
  const FieldOfViewInput({
    required this.sensorWidthMm,
    required this.sensorHeightMm,
    required this.focalLengthMm,
    required this.distanceMm,
  });
  final double sensorWidthMm;
  final double sensorHeightMm;
  final double focalLengthMm;
  final double distanceMm;
}

final class FieldOfViewOutput {
  const FieldOfViewOutput({
    required this.horizontalDegrees,
    required this.verticalDegrees,
    required this.diagonalDegrees,
    required this.sceneWidthMm,
    required this.sceneHeightMm,
  });
  final double horizontalDegrees;
  final double verticalDegrees;
  final double diagonalDegrees;
  final double sceneWidthMm;
  final double sceneHeightMm;
}

final class FieldOfViewCalculator {
  const FieldOfViewCalculator();
  static const id = 'field_of_view';
  static const version = 1;

  CalculationResult<FieldOfViewOutput> calculate(FieldOfViewInput input) {
    final errors = _positiveFields({
      'sensorWidthMm': input.sensorWidthMm,
      'sensorHeightMm': input.sensorHeightMm,
      'focalLengthMm': input.focalLengthMm,
      'distanceMm': input.distanceMm,
    });
    if (errors.isNotEmpty) {
      return CalculationResult.invalid(
        calculatorId: id,
        formulaVersion: version,
        errors: errors,
      );
    }
    double angle(double size) =>
        2 * math.atan(size / (2 * input.focalLengthMm));
    final horizontal = angle(input.sensorWidthMm);
    final vertical = angle(input.sensorHeightMm);
    final diagonal = angle(
      math.sqrt(
        input.sensorWidthMm * input.sensorWidthMm +
            input.sensorHeightMm * input.sensorHeightMm,
      ),
    );
    return CalculationResult.valid(
      calculatorId: id,
      formulaVersion: version,
      output: FieldOfViewOutput(
        horizontalDegrees: horizontal * 180 / math.pi,
        verticalDegrees: vertical * 180 / math.pi,
        diagonalDegrees: diagonal * 180 / math.pi,
        sceneWidthMm: 2 * input.distanceMm * math.tan(horizontal / 2),
        sceneHeightMm: 2 * input.distanceMm * math.tan(vertical / 2),
      ),
      assumptions: const [
        CalculationAssumption(key: 'projection', value: 'rectilinear'),
        CalculationAssumption(key: 'focus', value: 'nominalFocalLength'),
      ],
    );
  }
}

final class DiffractionInput {
  const DiffractionInput({
    required this.aperture,
    required this.wavelengthNm,
    required this.pixelPitchMicrometres,
  });
  final double aperture;
  final double wavelengthNm;
  final double pixelPitchMicrometres;
}

final class DiffractionOutput {
  const DiffractionOutput({
    required this.airyDiskMicrometres,
    required this.airyRadiusMicrometres,
    required this.airyDiskPixels,
  });
  final double airyDiskMicrometres;
  final double airyRadiusMicrometres;
  final double airyDiskPixels;
}

final class DiffractionCalculator {
  const DiffractionCalculator();
  static const id = 'diffraction';
  static const version = 1;

  CalculationResult<DiffractionOutput> calculate(DiffractionInput input) {
    final errors = _positiveFields({
      'aperture': input.aperture,
      'wavelengthNm': input.wavelengthNm,
      'pixelPitchMicrometres': input.pixelPitchMicrometres,
    });
    if (errors.isNotEmpty) {
      return CalculationResult.invalid(
        calculatorId: id,
        formulaVersion: version,
        errors: errors,
      );
    }
    final diameter = 2.44 * (input.wavelengthNm / 1000) * input.aperture;
    return CalculationResult.valid(
      calculatorId: id,
      formulaVersion: version,
      output: DiffractionOutput(
        airyDiskMicrometres: diameter,
        airyRadiusMicrometres: diameter / 2,
        airyDiskPixels: diameter / input.pixelPitchMicrometres,
      ),
      assumptions: const [
        CalculationAssumption(key: 'criterion', value: 'firstAiryMinimum'),
        CalculationAssumption(key: 'aperture', value: 'circular'),
        CalculationAssumption(key: 'wavelength', value: 'monochromatic'),
      ],
      warnings: diameter / input.pixelPitchMicrometres >= 2
          ? const [
              CalculationWarning(
                code: 'sampling_visible',
                messageKey: 'diffraction.warning.samplingVisible',
              ),
            ]
          : const [],
    );
  }
}

final class FocusStackInput {
  const FocusStackInput({
    required this.focalLengthMm,
    required this.aperture,
    required this.circleOfConfusionMm,
    required this.nearDistanceMm,
    required this.farDistanceMm,
    required this.overlapPercent,
  });
  final double focalLengthMm;
  final double aperture;
  final double circleOfConfusionMm;
  final double nearDistanceMm;
  final double farDistanceMm;
  final double overlapPercent;
}

final class FocusStackOutput {
  const FocusStackOutput({required this.focusDistancesMm});
  final List<double> focusDistancesMm;
  int get frameCount => focusDistancesMm.length;
}

final class FocusStackCalculator {
  const FocusStackCalculator();
  static const id = 'focus_stacking';
  static const version = 1;

  CalculationResult<FocusStackOutput> calculate(FocusStackInput input) {
    final errors = _positiveFields({
      'focalLengthMm': input.focalLengthMm,
      'aperture': input.aperture,
      'circleOfConfusionMm': input.circleOfConfusionMm,
      'nearDistanceMm': input.nearDistanceMm,
      'farDistanceMm': input.farDistanceMm,
    });
    if (input.nearDistanceMm.isFinite &&
        input.farDistanceMm.isFinite &&
        input.farDistanceMm <= input.nearDistanceMm) {
      errors.add(
        const ValidationError(
          field: 'farDistanceMm',
          code: 'greater_than_near',
          messageKey: 'focusStack.error.farDistance',
        ),
      );
    }
    if (!input.overlapPercent.isFinite ||
        input.overlapPercent < 0 ||
        input.overlapPercent >= 100) {
      errors.add(
        const ValidationError(
          field: 'overlapPercent',
          code: 'range',
          messageKey: 'focusStack.error.overlap',
        ),
      );
    }
    if (input.nearDistanceMm.isFinite &&
        input.nearDistanceMm <= input.focalLengthMm) {
      errors.add(
        const ValidationError(
          field: 'nearDistanceMm',
          code: 'not_beyond_focal_length',
          messageKey: 'focusStack.error.nearDistance',
        ),
      );
    }
    if (errors.isNotEmpty) {
      return CalculationResult.invalid(
        calculatorId: id,
        formulaVersion: version,
        errors: errors,
      );
    }

    final hyperfocal =
        input.focalLengthMm *
            input.focalLengthMm /
            (input.aperture * input.circleOfConfusionMm) +
        input.focalLengthMm;
    final usable = 1 - input.overlapPercent / 100;
    final positions = <double>[];
    var focus = input.nearDistanceMm;
    for (var index = 0; index < 1000 && focus < input.farDistanceMm; index++) {
      positions.add(focus);
      final far = focus >= hyperfocal
          ? double.infinity
          : focus * (hyperfocal - input.focalLengthMm) / (hyperfocal - focus);
      if (!far.isFinite || far >= input.farDistanceMm) break;
      final depthBehind = far - focus;
      final next = focus + depthBehind * usable;
      if (next <= focus + 1e-9) break;
      focus = math.min(next, input.farDistanceMm);
    }
    if (positions.isEmpty ||
        positions.last < input.farDistanceMm && positions.length < 1000) {
      positions.add(input.farDistanceMm);
    }
    final warnings = positions.length >= 1000
        ? const [
            CalculationWarning(
              code: 'frame_limit',
              messageKey: 'focusStack.warning.frameLimit',
            ),
          ]
        : const <CalculationWarning>[];
    return CalculationResult.valid(
      calculatorId: id,
      formulaVersion: version,
      output: FocusStackOutput(focusDistancesMm: List.unmodifiable(positions)),
      assumptions: const [
        CalculationAssumption(key: 'lensModel', value: 'thinLens'),
        CalculationAssumption(key: 'criterion', value: 'circleOfConfusion'),
        CalculationAssumption(key: 'movement', value: 'focusDistance'),
      ],
      warnings: warnings,
    );
  }
}

List<ValidationError> _positiveFields(Map<String, double> fields) => [
  for (final entry in fields.entries)
    if (!entry.value.isFinite || entry.value <= 0)
      ValidationError(
        field: entry.key,
        code: 'positive_finite_required',
        messageKey: 'optics.error.positiveFinite.${entry.key}',
      ),
];
