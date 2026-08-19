import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/domain/calculation_result.dart';
import 'package:photography_assistant/features/long_exposure/domain/long_exposure_calculator.dart';

import '../../../fixtures/long_exposure_fixtures.dart';

void main() {
  const calculator = LongExposureCalculator();

  for (final fixture in longExposureFixtures) {
    test(fixture.name, () {
      final result = calculator.calculate(
        LongExposureInput(
          baseTimeSeconds: fixture.baseTimeSeconds,
          filters: [
            for (final stops in fixture.filterStops) NdInput.stops(stops),
          ],
        ),
      );

      expect(result.status, CalculationStatus.valid);
      expect(result.calculatorId, LongExposureCalculator.id);
      expect(result.formulaVersion, LongExposureCalculator.version);
      expect(
        result.output!.totalStrength.stops,
        closeTo(fixture.totalStops, longExposureTolerance),
      );
      expect(
        result.output!.filteredTime.seconds,
        closeTo(fixture.filteredTimeSeconds, longExposureTolerance),
      );
    });
  }

  test('stacked filter order does not change the raw result', () {
    final first = calculator.calculate(
      const LongExposureInput(
        baseTimeSeconds: 1 / 30,
        filters: [NdInput.stops(3), NdInput.stops(7)],
      ),
    );
    final reversed = calculator.calculate(
      const LongExposureInput(
        baseTimeSeconds: 1 / 30,
        filters: [NdInput.stops(7), NdInput.stops(3)],
      ),
    );

    expect(
      reversed.output!.filteredTime.seconds,
      first.output!.filteredTime.seconds,
    );
  });

  test('factor and optical density convert to canonical stops', () {
    final result = calculator.calculate(
      const LongExposureInput(
        baseTimeSeconds: 1,
        filters: [NdInput.factor(8), NdInput.opticalDensity(0.9)],
      ),
    );

    expect(
      result.output!.appliedFilterStops[0].stops,
      closeTo(3, longExposureTolerance),
    );
    expect(
      result.output!.appliedFilterStops[1].stops,
      closeTo(0.9 * math.log(10) / math.ln2, longExposureTolerance),
    );
  });

  test('inverse calculation returns the filter needed for a target time', () {
    final result = calculator.calculate(
      const LongExposureInput(
        baseTimeSeconds: 1 / 125,
        filters: [],
        targetTimeSeconds: 8.192,
      ),
    );

    expect(
      result.output!.requiredStrength!.stops,
      closeTo(10, longExposureTolerance),
    );
  });

  test('long results request bulb or timer mode without rounding raw time', () {
    final result = calculator.calculate(
      const LongExposureInput(
        baseTimeSeconds: 1 / 30,
        filters: [NdInput.stops(10)],
      ),
    );

    expect(result.output!.requiresBulbOrTimer, isTrue);
    expect(result.output!.conventionalGuidance, '34.1 s');
    expect(
      result.output!.filteredTime.seconds,
      closeTo(34.13333333333333, 1e-12),
    );
  });

  test(
    'reports base, filter, and target validation errors in stable order',
    () {
      final result = calculator.calculate(
        const LongExposureInput(
          baseTimeSeconds: 0,
          filters: [
            NdInput.stops(-1),
            NdInput.factor(0),
            NdInput.opticalDensity(double.nan),
          ],
          targetTimeSeconds: -1,
        ),
      );

      expect(result.status, CalculationStatus.invalid);
      expect(result.errors.map((error) => error.field), [
        'baseTimeSeconds',
        'filters[0]',
        'filters[1]',
        'filters[2]',
        'targetTimeSeconds',
      ]);
    },
  );

  test('inverse target must not be shorter than the unfiltered exposure', () {
    final result = calculator.calculate(
      const LongExposureInput(
        baseTimeSeconds: 2,
        filters: [],
        targetTimeSeconds: 1,
      ),
    );

    expect(result.status, CalculationStatus.invalid);
    expect(result.errors.single.code, 'target_shorter_than_base');
  });
}
