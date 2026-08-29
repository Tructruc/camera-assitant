import 'dart:math' as math;

import '../../data/repositories/preferences_repository.dart';

/// Formats a duration at the user's selected photographic stop increment.
String formatConventionalShutter(double seconds, FractionStep step) {
  if (!seconds.isFinite || seconds <= 0) {
    throw ArgumentError.value(
      seconds,
      'seconds',
      'Must be finite and positive',
    );
  }

  final divisions = switch (step) {
    FractionStep.whole => 1,
    FractionStep.half => 2,
    FractionStep.third => 3,
  };
  final roundedStops = (math.log(seconds) / math.ln2 * divisions).round();
  final roundedSeconds = math.pow(2, roundedStops / divisions).toDouble();
  if (roundedSeconds >= 0.5) {
    return '${_decimal(roundedSeconds)} s';
  }

  final denominator = _nearestDenominator(1 / roundedSeconds, step);
  return '1/${_decimal(denominator)} s';
}

double _nearestDenominator(double target, FractionStep step) {
  final candidates = switch (step) {
    FractionStep.whole => const <double>[
      2,
      4,
      8,
      15,
      30,
      60,
      125,
      250,
      500,
      1000,
      2000,
      4000,
      8000,
    ],
    FractionStep.half => const <double>[
      2,
      3,
      4,
      6,
      8,
      11,
      15,
      22,
      30,
      45,
      60,
      90,
      125,
      180,
      250,
      350,
      500,
      750,
      1000,
      1500,
      2000,
      3000,
      4000,
      6000,
      8000,
    ],
    FractionStep.third => const <double>[
      2,
      2.5,
      3,
      4,
      5,
      6,
      8,
      10,
      13,
      15,
      20,
      25,
      30,
      40,
      50,
      60,
      80,
      100,
      125,
      160,
      200,
      250,
      320,
      400,
      500,
      640,
      800,
      1000,
      1250,
      1600,
      2000,
      2500,
      3200,
      4000,
      5000,
      6400,
      8000,
    ],
  };
  return candidates.reduce(
    (best, candidate) =>
        (math.log(candidate / target)).abs() < (math.log(best / target)).abs()
        ? candidate
        : best,
  );
}

String _decimal(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
