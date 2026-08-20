import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/domain/calculation_result.dart';
import 'package:photography_assistant/features/macro/domain/macro_calculator.dart';

void main() {
  const calculator = MacroCalculator();

  test('extension adds extension divided by focal length magnification', () {
    final result = calculator.calculate(
      const MacroInput.extensionTube(
        focalLengthMm: 50,
        extensionLengthMm: 25,
        nativeMagnification: 0.2,
        nominalAperture: 8,
        sensorWidthMm: 36,
      ),
    );
    expect(result.output!.magnification, closeTo(0.7, 1e-12));
    expect(result.output!.effectiveAperture, closeTo(13.6, 1e-12));
    expect(result.output!.subjectWidthMm, closeTo(51.428571, 1e-6));
  });

  test('reversed lens uses flange distance as an explicit estimate', () {
    final result = calculator.calculate(
      const MacroInput.reversedLens(
        reversedFocalLengthMm: 28,
        flangeDistanceMm: 44,
        nominalAperture: 5.6,
        sensorWidthMm: 36,
      ),
    );
    expect(result.output!.magnification, closeTo(44 / 28, 1e-12));
    expect(result.status, CalculationStatus.validWithWarning);
    expect(
      result.warnings.map((warning) => warning.code),
      contains('configuration_estimate'),
    );
  });

  test('coupled lenses use primary divided by reversed focal length', () {
    final result = calculator.calculate(
      const MacroInput.coupledLenses(
        primaryFocalLengthMm: 100,
        reversedFocalLengthMm: 50,
        nominalAperture: 8,
        sensorWidthMm: 36,
      ),
    );
    expect(result.output!.magnification, closeTo(2, 1e-12));
    expect(result.output!.subjectWidthMm, closeTo(18, 1e-12));
    expect(
      result.output!.exposureCompensationStops,
      closeTo(2 * 1.584962500721156, 1e-12),
    );
  });

  test('returns ordered validation errors for the active model only', () {
    final result = calculator.calculate(
      const MacroInput.extensionTube(
        focalLengthMm: 0,
        extensionLengthMm: -1,
        nativeMagnification: -0.1,
        nominalAperture: double.nan,
        sensorWidthMm: 0,
      ),
    );
    expect(result.status, CalculationStatus.invalid);
    expect(result.errors.map((error) => error.field), [
      'focalLengthMm',
      'extensionLengthMm',
      'nativeMagnification',
      'nominalAperture',
      'sensorWidthMm',
    ]);
  });
}
