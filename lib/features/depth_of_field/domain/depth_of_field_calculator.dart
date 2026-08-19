/// Versioned thin-lens depth-of-field and hyperfocal calculation.
library;

import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/quantities/quantities.dart';
import '../../../core/domain/validation/validation.dart';

/// Canonical calculator inputs, expressed in millimetres and an f-number.
final class DepthOfFieldInput {
  const DepthOfFieldInput({
    required this.focalLengthMm,
    required this.aperture,
    required this.focusDistanceMm,
    required this.circleOfConfusionMm,
  });

  final double focalLengthMm;
  final double aperture;
  final double focusDistanceMm;
  final double circleOfConfusionMm;
}

/// Physical result before display conversion or rounding.
final class DepthOfFieldOutput {
  const DepthOfFieldOutput({
    required this.hyperfocalDistance,
    required this.nearLimit,
    required this.farLimit,
    required this.totalDepth,
    required this.frontDepth,
    required this.rearDepth,
  });

  final Length hyperfocalDistance;
  final Length nearLimit;
  final FocusDistance farLimit;
  final FocusDistance totalDepth;
  final Length frontDepth;
  final FocusDistance rearDepth;
}

/// Pure deterministic implementation of the declared thin-lens equations.
final class DepthOfFieldCalculator {
  const DepthOfFieldCalculator();

  static const id = 'depth_of_field';
  static const version = 1;

  CalculationResult<DepthOfFieldOutput> calculate(DepthOfFieldInput input) {
    final errors = _validate(input);
    if (errors.isNotEmpty) {
      return CalculationResult.invalid(
        calculatorId: id,
        formulaVersion: version,
        errors: errors,
      );
    }

    final focalLength = input.focalLengthMm;
    final focusDistance = input.focusDistanceMm;
    final hyperfocal =
        (focalLength * focalLength) /
            (input.aperture * input.circleOfConfusionMm) +
        focalLength;
    final near =
        focusDistance *
        (hyperfocal - focalLength) /
        (hyperfocal + focusDistance - (2 * focalLength));
    final hyperfocalTolerance = hyperfocal * 1e-12;
    final farIsInfinite = focusDistance >= hyperfocal - hyperfocalTolerance;
    final far = farIsInfinite
        ? double.infinity
        : focusDistance *
              (hyperfocal - focalLength) /
              (hyperfocal - focusDistance);
    final warnings = <CalculationWarning>[
      if (focusDistance <= focalLength * 5)
        const CalculationWarning(
          code: 'close_focus',
          messageKey: 'depthOfField.warning.closeFocus',
        ),
    ];

    return CalculationResult.valid(
      calculatorId: id,
      formulaVersion: version,
      output: DepthOfFieldOutput(
        hyperfocalDistance: Length.millimetres(hyperfocal),
        nearLimit: Length.millimetres(near),
        farLimit: farIsInfinite
            ? FocusDistance.infinity
            : FocusDistance.millimetres(far),
        totalDepth: farIsInfinite
            ? FocusDistance.infinity
            : FocusDistance.millimetres(far - near),
        frontDepth: Length.millimetres(focusDistance - near),
        rearDepth: farIsInfinite
            ? FocusDistance.infinity
            : FocusDistance.millimetres(far - focusDistance),
      ),
      assumptions: const [
        CalculationAssumption(key: 'lensModel', value: 'thinLens'),
        CalculationAssumption(
          key: 'focusDistanceReference',
          value: 'lensPrincipalPlane',
        ),
        CalculationAssumption(
          key: 'circleOfConfusionModel',
          value: 'geometricCriterion',
        ),
      ],
      warnings: warnings,
    );
  }

  List<ValidationError> _validate(DepthOfFieldInput input) {
    final errors = <ValidationError>[];
    _requirePositiveFinite(errors, 'focalLengthMm', input.focalLengthMm);
    _requirePositiveFinite(errors, 'aperture', input.aperture);
    _requirePositiveFinite(errors, 'focusDistanceMm', input.focusDistanceMm);
    _requirePositiveFinite(
      errors,
      'circleOfConfusionMm',
      input.circleOfConfusionMm,
    );
    if (input.focalLengthMm.isFinite &&
        input.focalLengthMm > 0 &&
        input.focusDistanceMm.isFinite &&
        input.focusDistanceMm > 0 &&
        input.focusDistanceMm <= input.focalLengthMm) {
      errors.removeWhere((error) => error.field == 'focusDistanceMm');
      errors.add(
        const ValidationError(
          field: 'focusDistanceMm',
          code: 'not_beyond_focal_length',
          messageKey: 'depthOfField.error.focusBeyondFocalLength',
        ),
      );
    }
    return errors;
  }

  void _requirePositiveFinite(
    List<ValidationError> errors,
    String field,
    double value,
  ) {
    if (!value.isFinite || value <= 0) {
      errors.add(
        ValidationError(
          field: field,
          code: 'positive_finite_required',
          messageKey: 'depthOfField.error.positiveFinite.$field',
        ),
      );
    }
  }
}
