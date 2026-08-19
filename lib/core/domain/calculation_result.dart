/// Common result envelope shared by all deterministic calculators.
library;

import 'validation/validation.dart';

enum CalculationStatus { valid, validWithWarning, invalid }

/// An immutable result carrying formula identity and recovery information.
final class CalculationResult<T> {
  CalculationResult.valid({
    required this.calculatorId,
    required this.formulaVersion,
    required this.output,
    List<CalculationAssumption> assumptions = const [],
    List<CalculationWarning> warnings = const [],
  }) : assumptions = List.unmodifiable(assumptions),
       warnings = List.unmodifiable(warnings),
       errors = const [],
       status = warnings.isEmpty
           ? CalculationStatus.valid
           : CalculationStatus.validWithWarning {
    _validateIdentity(calculatorId, formulaVersion);
  }

  CalculationResult.invalid({
    required this.calculatorId,
    required this.formulaVersion,
    required List<ValidationError> errors,
  }) : output = null,
       assumptions = const [],
       warnings = const [],
       errors = List.unmodifiable(errors),
       status = CalculationStatus.invalid {
    _validateIdentity(calculatorId, formulaVersion);
    if (errors.isEmpty) {
      throw ArgumentError.value(errors, 'errors', 'must not be empty');
    }
  }

  final String calculatorId;
  final int formulaVersion;
  final CalculationStatus status;
  final T? output;
  final List<CalculationAssumption> assumptions;
  final List<CalculationWarning> warnings;
  final List<ValidationError> errors;

  bool get isUsable => status != CalculationStatus.invalid;

  static void _validateIdentity(String calculatorId, int formulaVersion) {
    if (calculatorId.trim().isEmpty) {
      throw ArgumentError.value(
        calculatorId,
        'calculatorId',
        'must not be empty',
      );
    }
    if (formulaVersion < 1) {
      throw ArgumentError.value(
        formulaVersion,
        'formulaVersion',
        'must be positive',
      );
    }
  }
}
