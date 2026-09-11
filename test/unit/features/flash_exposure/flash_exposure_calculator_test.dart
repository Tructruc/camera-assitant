import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/domain/calculation_result.dart';
import 'package:photography_assistant/core/domain/validation/validation.dart';
import 'package:photography_assistant/features/flash_exposure/domain/flash_exposure_calculator.dart';

void main() {
  const calculator = FlashExposureCalculator();

  test('guide number 40 at five metres recommends f/8', () {
    final result = calculator.calculate(
      const FlashExposureInput(
        guideNumberIso100Metres: 40,
        iso: 100,
        powerFraction: 1,
        subjectDistanceMetres: 5,
      ),
    );
    expect(result.output!.effectiveGuideNumberMetres, closeTo(40, 1e-12));
    expect(result.output!.recommendedAperture, closeTo(8, 1e-12));
    expect(result.output!.powerReductionStops, 0);
  });

  test('ISO 400 offsets quarter power', () {
    final result = calculator.calculate(
      const FlashExposureInput(
        guideNumberIso100Metres: 40,
        iso: 400,
        powerFraction: 0.25,
        subjectDistanceMetres: 5,
      ),
    );
    expect(result.output!.effectiveGuideNumberMetres, closeTo(40, 1e-12));
    expect(result.output!.recommendedAperture, closeTo(8, 1e-12));
    expect(result.output!.powerReductionStops, closeTo(2, 1e-12));
  });

  test('rejects invalid physical inputs and power above full', () {
    final result = calculator.calculate(
      const FlashExposureInput(
        guideNumberIso100Metres: 0,
        iso: double.nan,
        powerFraction: 2,
        subjectDistanceMetres: -1,
      ),
    );
    expect(result.status, CalculationStatus.invalid);
    expect(result.output, isNull);
    expect(result.errors, const [
      ValidationError(
        field: 'guideNumberIso100Metres',
        code: 'positive_finite_required',
        messageKey: 'flash.error.guideNumberIso100Metres',
      ),
      ValidationError(
        field: 'iso',
        code: 'positive_finite_required',
        messageKey: 'flash.error.iso',
      ),
      ValidationError(
        field: 'powerFraction',
        code: 'power_range',
        messageKey: 'flash.error.powerFraction',
      ),
      ValidationError(
        field: 'subjectDistanceMetres',
        code: 'positive_finite_required',
        messageKey: 'flash.error.subjectDistanceMetres',
      ),
    ]);
  });
}
