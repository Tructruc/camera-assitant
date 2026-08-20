/// Guide-number flash exposure planning.
library;

import 'dart:math' as math;

import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/validation/validation.dart';

final class FlashExposureInput {
  const FlashExposureInput({
    required this.guideNumberIso100Metres,
    required this.iso,
    required this.powerFraction,
    required this.subjectDistanceMetres,
  });

  final double guideNumberIso100Metres;
  final double iso;
  final double powerFraction;
  final double subjectDistanceMetres;
}

final class FlashExposureOutput {
  const FlashExposureOutput({
    required this.effectiveGuideNumberMetres,
    required this.recommendedAperture,
    required this.powerReductionStops,
    required this.fullPowerRangeAtRecommendedApertureMetres,
  });

  final double effectiveGuideNumberMetres;
  final double recommendedAperture;
  final double powerReductionStops;
  final double fullPowerRangeAtRecommendedApertureMetres;
}

final class FlashExposureCalculator {
  const FlashExposureCalculator();

  static const id = 'flash_exposure';
  static const version = 1;

  CalculationResult<FlashExposureOutput> calculate(FlashExposureInput input) {
    final errors = <ValidationError>[];
    _positive(errors, 'guideNumberIso100Metres', input.guideNumberIso100Metres);
    _positive(errors, 'iso', input.iso);
    if (!input.powerFraction.isFinite ||
        input.powerFraction <= 0 ||
        input.powerFraction > 1) {
      errors.add(
        const ValidationError(
          field: 'powerFraction',
          code: 'power_range',
          messageKey: 'flash.error.powerFraction',
        ),
      );
    }
    _positive(errors, 'subjectDistanceMetres', input.subjectDistanceMetres);
    if (errors.isNotEmpty) {
      return CalculationResult.invalid(
        calculatorId: id,
        formulaVersion: version,
        errors: errors,
      );
    }

    final isoScale = math.sqrt(input.iso / 100);
    final powerScale = math.sqrt(input.powerFraction);
    final effectiveGuideNumber =
        input.guideNumberIso100Metres * isoScale * powerScale;
    final aperture = effectiveGuideNumber / input.subjectDistanceMetres;
    return CalculationResult.valid(
      calculatorId: id,
      formulaVersion: version,
      output: FlashExposureOutput(
        effectiveGuideNumberMetres: effectiveGuideNumber,
        recommendedAperture: aperture,
        powerReductionStops: -math.log(input.powerFraction) / math.ln2,
        fullPowerRangeAtRecommendedApertureMetres:
            input.guideNumberIso100Metres * isoScale / aperture,
      ),
      assumptions: const [
        CalculationAssumption(key: 'guideNumberUnits', value: 'metresAtIso100'),
        CalculationAssumption(key: 'lightPath', value: 'directFlash'),
        CalculationAssumption(
          key: 'environment',
          value: 'nominalManufacturerRating',
        ),
      ],
      warnings: aperture < 1 || aperture > 64
          ? const [
              CalculationWarning(
                code: 'aperture_outside_typical_range',
                messageKey: 'flash.warning.apertureRange',
              ),
            ]
          : const [],
    );
  }
}

void _positive(List<ValidationError> errors, String field, double value) {
  if (!value.isFinite || value <= 0) {
    errors.add(
      ValidationError(
        field: field,
        code: 'positive_finite_required',
        messageKey: 'flash.error.$field',
      ),
    );
  }
}
