import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/domain/calculation_result.dart';
import 'package:photography_assistant/features/exposure_comparison/domain/exposure_calculator.dart';

import '../../../fixtures/exposure_fixtures.dart';

void main() {
  const calculator = ExposureCalculator();

  for (final fixture in exposureFixtures) {
    test(fixture.name, () {
      final result = calculator.calculate(
        ExposureComparisonInput(
          baseline: ExposureTriple(
            aperture: fixture.baselineAperture,
            timeSeconds: fixture.baselineTimeSeconds,
            iso: fixture.baselineIso,
          ),
          candidate: ExposureTriple(
            aperture: fixture.candidateAperture,
            timeSeconds: fixture.candidateTimeSeconds,
            iso: fixture.candidateIso,
          ),
        ),
      );

      expect(result.status, CalculationStatus.valid);
      expect(result.calculatorId, ExposureCalculator.id);
      expect(result.formulaVersion, ExposureCalculator.version);
      final output = result.output!;
      expect(
        output.apertureContribution.stops,
        closeTo(fixture.apertureStops, exposureTolerance),
      );
      expect(
        output.timeContribution.stops,
        closeTo(fixture.timeStops, exposureTolerance),
      );
      expect(
        output.isoContribution.stops,
        closeTo(fixture.isoStops, exposureTolerance),
      );
      expect(
        output.totalDifference.stops,
        closeTo(fixture.totalStops, exposureTolerance),
      );
      expect(output.multiplier, closeTo(fixture.multiplier, exposureTolerance));
    });
  }

  test('swapping exposures negates stops and reciprocates the multiplier', () {
    const baseline = ExposureTriple(aperture: 8, timeSeconds: 0.01, iso: 100);
    const candidate = ExposureTriple(aperture: 4, timeSeconds: 0.04, iso: 200);

    final forward = calculator.calculate(
      const ExposureComparisonInput(baseline: baseline, candidate: candidate),
    );
    final reverse = calculator.calculate(
      const ExposureComparisonInput(baseline: candidate, candidate: baseline),
    );

    expect(
      reverse.output!.totalDifference.stops,
      closeTo(-forward.output!.totalDifference.stops, exposureTolerance),
    );
    expect(
      reverse.output!.multiplier,
      closeTo(1 / forward.output!.multiplier, exposureTolerance),
    );
    expect(forward.output!.direction, ExposureDirection.brighter);
    expect(reverse.output!.direction, ExposureDirection.darker);
  });

  test('component contributions sum to the total', () {
    final result = calculator.calculate(
      const ExposureComparisonInput(
        baseline: ExposureTriple(aperture: 2.8, timeSeconds: 1 / 125, iso: 100),
        candidate: ExposureTriple(aperture: 5.6, timeSeconds: 1 / 30, iso: 400),
      ),
    );
    final output = result.output!;
    final sum =
        output.apertureContribution.stops +
        output.timeContribution.stops +
        output.isoContribution.stops;

    expect(output.totalDifference.stops, closeTo(sum, exposureTolerance));
  });

  test('reports all invalid fields in stable baseline-first order', () {
    final result = calculator.calculate(
      const ExposureComparisonInput(
        baseline: ExposureTriple(aperture: 0, timeSeconds: -1, iso: double.nan),
        candidate: ExposureTriple(
          aperture: double.infinity,
          timeSeconds: 0,
          iso: -100,
        ),
      ),
    );

    expect(result.status, CalculationStatus.invalid);
    expect(result.errors.map((error) => error.field), [
      'baseline.aperture',
      'baseline.timeSeconds',
      'baseline.iso',
      'candidate.aperture',
      'candidate.timeSeconds',
      'candidate.iso',
    ]);
  });
}
