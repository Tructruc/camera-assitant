import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:photography_assistant/features/exposure_comparison/domain/exposure_calculator.dart';
import 'package:photography_assistant/features/flash_exposure/domain/flash_exposure_calculator.dart';
import 'package:photography_assistant/features/long_exposure/domain/long_exposure_calculator.dart';

/// Randomized property sweep over the exposure calculators.
///
/// These three share one shape of bug: the app publishes several numbers that
/// are *defined* in terms of each other (the stop contributions must add up to
/// the total, the multiplier must be two to the total, the flash aperture must
/// satisfy the guide-number law, a filtered exposure must be the base scaled by
/// the filters, and the bulb flag must follow the resulting time). A wrong
/// number that is internally consistent still looks fine to a test that only
/// checks the case somebody wrote down; a number that breaks its own
/// definition does not. So each assertion here compares the calculator against
/// the definition of its output, on 500 inputs drawn logarithmically across
/// the documented ranges.
void main() {
  final random = math.Random(20260925);

  double logUniform(double min, double max) =>
      min * math.pow(max / min, random.nextDouble());

  void expectClose(
    List<String> violations,
    String label,
    double actual,
    double expected,
  ) {
    if (!actual.isFinite) {
      violations.add('$label is $actual (expected $expected)');
      return;
    }
    final tolerance = math.max(expected.abs() * 1e-9, 1e-9);
    if ((actual - expected).abs() > tolerance) {
      violations.add('$label is $actual, should be $expected');
    }
  }

  const samples = 500;

  test(
    'exposure comparison adds up and still describes its own multiplier',
    () {
      final violations = <String>[];
      var rejected = 0;
      for (var i = 0; i < samples; i++) {
        final baseline = ExposureTriple(
          aperture: logUniform(0.95, 64),
          timeSeconds: logUniform(1 / 8000, 3600),
          iso: logUniform(25, 409600),
        );
        final candidate = ExposureTriple(
          aperture: logUniform(0.95, 64),
          timeSeconds: logUniform(1 / 8000, 3600),
          iso: logUniform(25, 409600),
        );

        final result = const ExposureCalculator().calculate(
          ExposureComparisonInput(baseline: baseline, candidate: candidate),
        );
        final context = 'baseline=$baseline candidate=$candidate';
        if (!result.isUsable) {
          final codes = result.errors.map((error) => error.code).toSet();
          if (!codes.every((code) => code == 'result_out_of_range')) {
            violations.add('rejected with $codes $context');
          }
          rejected++;
          continue;
        }

        final output = result.output!;
        final total = output.totalDifference.stops;
        final sum =
            output.apertureContribution.stops +
            output.timeContribution.stops +
            output.isoContribution.stops;

        expectClose(violations, 'total stops', total, sum);
        expectClose(
          violations,
          'multiplier',
          output.multiplier,
          math.pow(2, total).toDouble(),
        );

        // The direction is the word the UI prints for that number, so it has to
        // agree with the sign of the number beside it.
        final expectedDirection = total > 1e-9
            ? ExposureDirection.brighter
            : total < -1e-9
            ? ExposureDirection.darker
            : ExposureDirection.equivalent;
        if (output.direction != expectedDirection) {
          violations.add(
            'direction ${output.direction} for $total stops total $context',
          );
        }
      }
      expect(
        violations.take(5),
        isEmpty,
        reason: '${violations.length} violations',
      );
      // A sweep that mostly refuses its inputs would prove nothing about the
      // arithmetic, so most of the samples have to get through the validators.
      expect(
        rejected,
        lessThan(samples ~/ 2),
        reason: '$rejected of $samples inputs were refused',
      );
    },
  );

  test('the same exposure compared with itself is an equivalence', () {
    for (var i = 0; i < 50; i++) {
      final triple = ExposureTriple(
        aperture: logUniform(0.95, 64),
        timeSeconds: logUniform(1 / 8000, 3600),
        iso: logUniform(25, 409600),
      );
      final output = const ExposureCalculator()
          .calculate(
            ExposureComparisonInput(baseline: triple, candidate: triple),
          )
          .output!;

      expect(output.totalDifference.stops, closeTo(0, 1e-12));
      expect(output.multiplier, closeTo(1, 1e-12));
      expect(output.direction, ExposureDirection.equivalent);
    }
  });

  test('flash exposure obeys the guide number law it reports', () {
    final violations = <String>[];
    var rejected = 0;
    for (var i = 0; i < samples; i++) {
      final guideNumber = logUniform(1, 100);
      final iso = logUniform(25, 409600);
      final power = logUniform(1 / 256, 1);
      final distance = logUniform(0.1, 100);
      final result = const FlashExposureCalculator().calculate(
        FlashExposureInput(
          guideNumberIso100Metres: guideNumber,
          iso: iso,
          powerFraction: power,
          subjectDistanceMetres: distance,
        ),
      );
      final context =
          'gn=$guideNumber iso=$iso power=$power distance=$distance';

      if (!result.isUsable) {
        final codes = result.errors.map((error) => error.code).toSet();
        if (!codes.every((code) => code == 'result_out_of_range')) {
          violations.add('rejected with $codes $context');
        }
        rejected++;
        continue;
      }

      final output = result.output!;
      final effective = guideNumber * math.sqrt(iso / 100) * math.sqrt(power);

      expectClose(
        violations,
        'effective guide number',
        output.effectiveGuideNumberMetres,
        effective,
      );
      expectClose(
        violations,
        'aperture x distance',
        output.recommendedAperture * distance,
        output.effectiveGuideNumberMetres,
      );
      expectClose(
        violations,
        'power reduction stops',
        output.powerReductionStops,
        -math.log(power) / math.ln2,
      );
      // At full power the range is the subject distance; each stop of power
      // reduction shortens it by the square root of the power fraction.
      expectClose(
        violations,
        'full power range',
        output.fullPowerRangeAtRecommendedApertureMetres,
        distance / math.sqrt(power),
      );
    }
    expect(
      violations.take(5),
      isEmpty,
      reason: '${violations.length} violations',
    );
    // A sweep that mostly refuses its inputs would prove nothing about the
    // arithmetic, so most of the samples have to get through the validators.
    expect(
      rejected,
      lessThan(samples ~/ 2),
      reason: '$rejected of $samples inputs were refused',
    );
  });

  test('a filtered exposure is the base scaled by the filters it accepted', () {
    final violations = <String>[];
    var rejected = 0;
    for (var i = 0; i < samples; i++) {
      final base = logUniform(1 / 8000, 3600);
      final filters = <NdInput>[
        for (var index = 0; index < random.nextInt(4); index++)
          switch (random.nextInt(3)) {
            0 => NdInput.stops(logUniform(0.5, 30)),
            1 => NdInput.factor(logUniform(2, 1000)),
            _ => NdInput.opticalDensity(logUniform(0.1, 6)),
          },
      ];
      final target = random.nextBool() ? logUniform(base, base * 1e6) : null;
      final result = const LongExposureCalculator().calculate(
        LongExposureInput(
          baseTimeSeconds: base,
          filters: filters,
          targetTimeSeconds: target,
        ),
      );
      final context =
          'base=$base filters=${filters.map((f) => '${f.kind}:${f.value}').toList()} target=$target';

      if (!result.isUsable) {
        final codes = result.errors.map((error) => error.code).toSet();
        if (!codes.every(
          (code) => code == 'result_out_of_range' || code == 'range',
        )) {
          violations.add('rejected with $codes $context');
        }
        rejected++;
        continue;
      }

      final output = result.output!;
      final applied = output.appliedFilterStops
          .map((strength) => strength.stops)
          .toList();
      if (applied.length != filters.length) {
        violations.add(
          '${applied.length} filter stops for ${filters.length} filters $context',
        );
      }

      final total = applied.fold<double>(0, (sum, stops) => sum + stops);
      expectClose(
        violations,
        'total strength',
        output.totalStrength.stops,
        total,
      );
      expectClose(
        violations,
        'filtered time',
        output.filteredTime.seconds,
        base * math.pow(2, total).toDouble(),
      );
      if (output.requiresBulbOrTimer != (output.filteredTime.seconds > 30)) {
        violations.add(
          'bulb flag ${output.requiresBulbOrTimer} at '
          '${output.filteredTime.seconds}s $context',
        );
      }
      if (target != null) {
        final required = output.requiredStrength?.stops;
        if (required == null) {
          violations.add('target set but no required strength $context');
        } else {
          expectClose(
            violations,
            'required strength',
            required,
            math.log(target / base) / math.ln2,
          );
        }
      } else if (output.requiredStrength != null) {
        violations.add('required strength without a target $context');
      }
    }
    expect(
      violations.take(5),
      isEmpty,
      reason: '${violations.length} violations',
    );
    // A sweep that mostly refuses its inputs would prove nothing about the
    // arithmetic, so most of the samples have to get through the validators.
    expect(
      rejected,
      lessThan(samples ~/ 2),
      reason: '$rejected of $samples inputs were refused',
    );
  });
}
