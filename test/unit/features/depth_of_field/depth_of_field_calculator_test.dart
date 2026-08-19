import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/domain/calculation_result.dart';
import 'package:photography_assistant/features/depth_of_field/domain/depth_of_field_calculator.dart';

import '../../../fixtures/depth_of_field_fixtures.dart';

void main() {
  const calculator = DepthOfFieldCalculator();

  for (final fixture in depthOfFieldFixtures) {
    test(fixture.name, () {
      final result = calculator.calculate(
        DepthOfFieldInput(
          focalLengthMm: fixture.focalLengthMm,
          aperture: fixture.aperture,
          focusDistanceMm: fixture.focusDistanceMm,
          circleOfConfusionMm: fixture.circleOfConfusionMm,
        ),
      );

      expect(result.status, isNot(CalculationStatus.invalid));
      expect(result.calculatorId, DepthOfFieldCalculator.id);
      expect(result.formulaVersion, DepthOfFieldCalculator.version);
      final output = result.output!;
      expect(
        output.hyperfocalDistance.millimetres,
        closeTo(fixture.hyperfocalDistanceMm, depthOfFieldToleranceMm),
      );
      expect(
        output.nearLimit.millimetres,
        closeTo(fixture.nearLimitMm, depthOfFieldToleranceMm),
      );
      if (fixture.farLimitMm case final expected?) {
        expect(output.farLimit.isInfinite, isFalse);
        expect(
          output.farLimit.millimetres,
          closeTo(expected, depthOfFieldToleranceMm),
        );
        expect(
          output.totalDepth.millimetres,
          closeTo(expected - fixture.nearLimitMm, depthOfFieldToleranceMm),
        );
      } else {
        expect(output.farLimit.isInfinite, isTrue);
        expect(output.totalDepth.isInfinite, isTrue);
      }
    });
  }

  test('reports ordered field errors instead of throwing', () {
    final result = calculator.calculate(
      const DepthOfFieldInput(
        focalLengthMm: double.nan,
        aperture: 0,
        focusDistanceMm: -1,
        circleOfConfusionMm: double.infinity,
      ),
    );

    expect(result.status, CalculationStatus.invalid);
    expect(result.errors.map((error) => error.field), [
      'focalLengthMm',
      'aperture',
      'focusDistanceMm',
      'circleOfConfusionMm',
    ]);
  });

  test('rejects focus distance at or inside the focal length', () {
    final result = calculator.calculate(
      const DepthOfFieldInput(
        focalLengthMm: 100,
        aperture: 8,
        focusDistanceMm: 100,
        circleOfConfusionMm: 0.03,
      ),
    );

    expect(result.status, CalculationStatus.invalid);
    expect(result.errors.single.field, 'focusDistanceMm');
    expect(result.errors.single.code, 'not_beyond_focal_length');
  });

  test('declares thin-lens assumptions and close-focus limitation', () {
    final result = calculator.calculate(
      const DepthOfFieldInput(
        focalLengthMm: 100,
        aperture: 4,
        focusDistanceMm: 300,
        circleOfConfusionMm: 0.03,
      ),
    );

    expect(result.status, CalculationStatus.validWithWarning);
    expect(result.assumptions.map((item) => item.key), contains('lensModel'));
    expect(result.warnings.map((item) => item.code), contains('close_focus'));
  });

  test('equivalent millimetre inputs produce identical physical results', () {
    final first = calculator.calculate(
      const DepthOfFieldInput(
        focalLengthMm: 50,
        aperture: 8,
        focusDistanceMm: 10000,
        circleOfConfusionMm: 0.03,
      ),
    );
    final converted = calculator.calculate(
      const DepthOfFieldInput(
        focalLengthMm: 0.05 * 1000,
        aperture: 8,
        focusDistanceMm: 10 * 1000,
        circleOfConfusionMm: 0.003 * 10,
      ),
    );

    expect(converted.output!.nearLimit, first.output!.nearLimit);
    expect(
      converted.output!.farLimit.millimetres,
      first.output!.farLimit.millimetres,
    );
  });
}
