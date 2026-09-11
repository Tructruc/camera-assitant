/// Versioned exposure-triangle comparison using base-2 stop arithmetic.
library;

import 'dart:math' as math;

import '../../../core/domain/calculation_result.dart';
import '../../../core/domain/quantities/quantities.dart';
import '../../../core/domain/validation/validation.dart';

final class ExposureTriple {
  const ExposureTriple({
    required this.aperture,
    required this.timeSeconds,
    required this.iso,
  });

  final double aperture;
  final double timeSeconds;
  final double iso;
}

final class ExposureComparisonInput {
  const ExposureComparisonInput({
    required this.baseline,
    required this.candidate,
  });

  final ExposureTriple baseline;
  final ExposureTriple candidate;
}

enum ExposureDirection { brighter, equivalent, darker }

final class ExposureComparisonOutput {
  const ExposureComparisonOutput({
    required this.totalDifference,
    required this.apertureContribution,
    required this.timeContribution,
    required this.isoContribution,
    required this.multiplier,
    required this.direction,
  });

  final StopDifference totalDifference;
  final StopDifference apertureContribution;
  final StopDifference timeContribution;
  final StopDifference isoContribution;
  final double multiplier;
  final ExposureDirection direction;
}

final class ExposureCalculator {
  const ExposureCalculator();

  static const id = 'exposure_comparison';
  static const version = 1;

  CalculationResult<ExposureComparisonOutput> calculate(
    ExposureComparisonInput input,
  ) {
    final errors = _validate(input);
    if (errors.isNotEmpty) {
      return CalculationResult.invalid(
        calculatorId: id,
        formulaVersion: version,
        errors: errors,
      );
    }

    final apertureStops =
        2 * _log2(input.baseline.aperture / input.candidate.aperture);
    final timeStops = _log2(
      input.candidate.timeSeconds / input.baseline.timeSeconds,
    );
    final isoStops = _log2(input.candidate.iso / input.baseline.iso);
    final totalStops = apertureStops + timeStops + isoStops;
    // A ratio of extreme but individually valid inputs can overflow the
    // logarithm; the result is not representable, so say which side it came
    // from instead of letting the stop value object throw (FR-002).
    final unrepresentable = <String>[
      if (!apertureStops.isFinite) 'baseline.aperture',
      if (!timeStops.isFinite) 'baseline.timeSeconds',
      if (!isoStops.isFinite) 'baseline.iso',
    ];
    if (unrepresentable.isNotEmpty) {
      return CalculationResult.invalid(
        calculatorId: id,
        formulaVersion: version,
        errors: [
          for (final field in unrepresentable)
            ValidationError(
              field: field,
              code: 'result_out_of_range',
              messageKey: 'exposure.error.resultOutOfRange',
            ),
        ],
      );
    }
    final direction = switch (totalStops) {
      > 0 => ExposureDirection.brighter,
      < 0 => ExposureDirection.darker,
      _ => ExposureDirection.equivalent,
    };
    final multiplier = math.pow(2, totalStops).toDouble();
    // Finite stop differences can still push the linear multiplier past the
    // representable range (overflow to infinity or underflow to zero), which
    // is not a usable "N×" comparison factor.
    if (!multiplier.isFinite || multiplier <= 0) {
      return CalculationResult.invalid(
        calculatorId: id,
        formulaVersion: version,
        errors: [
          ValidationError(
            field: _multiplierField(
              totalStops,
              apertureStops,
              timeStops,
              isoStops,
            ),
            code: 'result_out_of_range',
            messageKey: 'exposure.error.resultOutOfRange',
          ),
        ],
      );
    }

    return CalculationResult.valid(
      calculatorId: id,
      formulaVersion: version,
      output: ExposureComparisonOutput(
        totalDifference: StopDifference(totalStops),
        apertureContribution: StopDifference(apertureStops),
        timeContribution: StopDifference(timeStops),
        isoContribution: StopDifference(isoStops),
        multiplier: multiplier,
        direction: direction,
      ),
      assumptions: const [
        CalculationAssumption(
          key: 'exposureModel',
          value: 'apertureShutterIso',
        ),
        CalculationAssumption(key: 'stopBase', value: '2'),
      ],
    );
  }

  List<ValidationError> _validate(ExposureComparisonInput input) {
    final errors = <ValidationError>[];
    _validateTriple(errors, 'baseline', input.baseline);
    _validateTriple(errors, 'candidate', input.candidate);
    return errors;
  }

  void _validateTriple(
    List<ValidationError> errors,
    String prefix,
    ExposureTriple exposure,
  ) {
    _requirePositiveFinite(errors, '$prefix.aperture', exposure.aperture);
    _requirePositiveFinite(errors, '$prefix.timeSeconds', exposure.timeSeconds);
    _requirePositiveFinite(errors, '$prefix.iso', exposure.iso);
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
          messageKey: 'exposure.error.positiveFinite.$field',
        ),
      );
    }
  }

  double _log2(double value) => math.log(value) / math.ln2;
}

/// Names the endpoint whose stop contribution pushed the linear multiplier out
/// of range, so the UI highlights the side the user should change.
String _multiplierField(
  double totalStops,
  double apertureStops,
  double timeStops,
  double isoStops,
) {
  final contributions = <(String, double)>[
    ('baseline.aperture', apertureStops),
    ('baseline.timeSeconds', timeStops),
    ('baseline.iso', isoStops),
  ];
  // A brighter candidate (positive stops) comes from the candidate's smaller
  // aperture, longer time, or higher ISO; mirror the field names accordingly.
  final candidateSide = totalStops > 0;
  String? bestField;
  var bestMagnitude = -1.0;
  for (final (field, stops) in contributions) {
    final magnitude = candidateSide ? stops : -stops;
    if (magnitude > bestMagnitude) {
      bestMagnitude = magnitude;
      bestField = candidateSide
          ? field.replaceFirst('baseline.', 'candidate.')
          : field;
    }
  }
  return bestField ?? 'candidate.aperture';
}
