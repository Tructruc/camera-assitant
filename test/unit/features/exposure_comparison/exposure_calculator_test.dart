import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/core/domain/calculation_result.dart';
import 'package:photography_assistant/core/domain/validation/validation.dart';
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

  test('reports absolute stop contributions for a real exposure change', () {
    final result = calculator.calculate(
      const ExposureComparisonInput(
        baseline: ExposureTriple(aperture: 2.8, timeSeconds: 1 / 125, iso: 100),
        candidate: ExposureTriple(aperture: 5.6, timeSeconds: 1 / 30, iso: 400),
      ),
    );
    final output = result.output!;

    // f/2.8 -> f/5.6 halves the light twice: -2.0 stops.
    expect(output.apertureContribution.stops, closeTo(-2.0, 1e-9));
    // 1/125 s -> 1/30 s is log2(125 / 30) stops of additional light.
    expect(output.timeContribution.stops, closeTo(2.0588936890535687, 1e-9));
    // ISO 100 -> ISO 400 doubles the sensitivity twice: +2.0 stops.
    expect(output.isoContribution.stops, closeTo(2.0, 1e-9));
    // Total: -2.0 + 2.0588936890535687 + 2.0.
    expect(output.totalDifference.stops, closeTo(2.0588936890535687, 1e-9));
    // 2 ** 2.0588936890535687 == 125 / 30.
    expect(output.multiplier, closeTo(4.166666666666667, 1e-6));
    expect(output.direction, ExposureDirection.brighter);
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
    expect(result.output, isNull);
    expect(result.errors, const [
      ValidationError(
        field: 'baseline.aperture',
        code: 'positive_finite_required',
        messageKey: 'exposure.error.positiveFinite.baseline.aperture',
      ),
      ValidationError(
        field: 'baseline.timeSeconds',
        code: 'positive_finite_required',
        messageKey: 'exposure.error.positiveFinite.baseline.timeSeconds',
      ),
      ValidationError(
        field: 'baseline.iso',
        code: 'positive_finite_required',
        messageKey: 'exposure.error.positiveFinite.baseline.iso',
      ),
      ValidationError(
        field: 'candidate.aperture',
        code: 'positive_finite_required',
        messageKey: 'exposure.error.positiveFinite.candidate.aperture',
      ),
      ValidationError(
        field: 'candidate.timeSeconds',
        code: 'positive_finite_required',
        messageKey: 'exposure.error.positiveFinite.candidate.timeSeconds',
      ),
      ValidationError(
        field: 'candidate.iso',
        code: 'positive_finite_required',
        messageKey: 'exposure.error.positiveFinite.candidate.iso',
      ),
    ]);
  });
}
