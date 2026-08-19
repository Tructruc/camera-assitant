/// Typed, presentation-independent calculation context and validation issues.
library;

/// A field-specific validation failure with a localizable recovery message.
final class ValidationError {
  const ValidationError({
    required this.field,
    required this.code,
    required this.messageKey,
  });

  final String field;
  final String code;
  final String messageKey;
}

/// A non-fatal limitation attached to an otherwise usable result.
final class CalculationWarning {
  const CalculationWarning({required this.code, required this.messageKey});

  final String code;
  final String messageKey;
}

/// A named model choice or convention used to produce a result.
final class CalculationAssumption {
  const CalculationAssumption({required this.key, required this.value});

  final String key;
  final String value;
}
