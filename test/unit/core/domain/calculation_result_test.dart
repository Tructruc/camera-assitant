import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/domain/calculation_result.dart';
import 'package:photography_assistant/core/domain/validation/validation.dart';

void main() {
  test('valid results retain formula identity and ordered context', () {
    final result = CalculationResult<double>.valid(
      calculatorId: 'depth-of-field',
      formulaVersion: 1,
      output: 42,
      assumptions: const [
        CalculationAssumption(key: 'model', value: 'thin-lens'),
      ],
    );

    expect(result.status, CalculationStatus.valid);
    expect(result.output, 42);
    expect(result.isUsable, isTrue);
    expect(result.assumptions.single.key, 'model');
  });

  test('warnings produce a usable valid-with-warning result', () {
    final result = CalculationResult<double>.valid(
      calculatorId: 'depth-of-field',
      formulaVersion: 1,
      output: 42,
      warnings: const [
        CalculationWarning(
          code: 'close-focus',
          messageKey: 'warning.closeFocus',
        ),
      ],
    );

    expect(result.status, CalculationStatus.validWithWarning);
    expect(result.isUsable, isTrue);
  });

  test(
    'invalid results expose ordered field recovery errors and no output',
    () {
      final result = CalculationResult<double>.invalid(
        calculatorId: 'depth-of-field',
        formulaVersion: 1,
        errors: const [
          ValidationError(
            field: 'aperture',
            code: 'positive',
            messageKey: 'validation.positive',
          ),
        ],
      );

      expect(result.status, CalculationStatus.invalid);
      expect(result.output, isNull);
      expect(result.isUsable, isFalse);
      expect(result.errors.single.field, 'aperture');
    },
  );

  test('invalid result requires at least one validation error', () {
    expect(
      () => CalculationResult<double>.invalid(
        calculatorId: 'depth-of-field',
        formulaVersion: 1,
        errors: const [],
      ),
      throwsArgumentError,
    );
  });

  test('a usable result cannot be constructed without a non-null output', () {
    expect(
      () => CalculationResult<double>.valid(
        calculatorId: 'depth-of-field',
        formulaVersion: 1,
        output: null,
      ),
      throwsArgumentError,
    );
  });

  test('nullable outputs are still allowed when the type admits null', () {
    final result = CalculationResult<double?>.valid(
      calculatorId: 'depth-of-field',
      formulaVersion: 1,
      output: null,
    );

    expect(result.status, CalculationStatus.valid);
    expect(result.isUsable, isTrue);
    expect(result.output, isNull);
    expect(result.errors, isEmpty);
  });

  test('validation issues compare by value', () {
    expect(
      const ValidationError(
        field: 'aperture',
        code: 'positive_finite_required',
        messageKey: 'dof.error.aperture',
      ),
      const ValidationError(
        field: 'aperture',
        code: 'positive_finite_required',
        messageKey: 'dof.error.aperture',
      ),
    );
    expect(
      const ValidationError(
        field: 'aperture',
        code: 'positive_finite_required',
        messageKey: 'dof.error.aperture',
      ),
      isNot(
        const ValidationError(
          field: 'aperture',
          code: 'range',
          messageKey: 'dof.error.aperture',
        ),
      ),
    );
    expect(
      const CalculationWarning(code: 'close-focus', messageKey: 'warning.x'),
      const CalculationWarning(code: 'close-focus', messageKey: 'warning.x'),
    );
    expect(
      const CalculationAssumption(key: 'model', value: 'thin-lens'),
      const CalculationAssumption(key: 'model', value: 'thin-lens'),
    );
  });
}
