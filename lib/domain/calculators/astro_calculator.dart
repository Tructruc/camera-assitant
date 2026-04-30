import 'dart:math' as math;

enum AstroShutterRule { rule500, rule400, rule300 }

extension AstroShutterRuleValues on AstroShutterRule {
  double get divisor => switch (this) {
        AstroShutterRule.rule500 => 500,
        AstroShutterRule.rule400 => 400,
        AstroShutterRule.rule300 => 300,
      };
}

class AstroCalculatorResult {
  const AstroCalculatorResult({
    required this.cropFactor,
    required this.equivalentFocalLengthMm,
    required this.maxShutterSeconds,
  });

  final double cropFactor;
  final double equivalentFocalLengthMm;
  final double maxShutterSeconds;
}

class AstroCalculator {
  static const _fullFrameWidthMm = 36.0;
  static const _fullFrameHeightMm = 24.0;

  static AstroCalculatorResult calculateMaxShutter({
    required double focalLengthMm,
    required double sensorWidthMm,
    required double sensorHeightMm,
    required AstroShutterRule rule,
  }) {
    final cropFactor = _cropFactor(
      sensorWidthMm: sensorWidthMm,
      sensorHeightMm: sensorHeightMm,
    );
    final equivalentFocalLengthMm = focalLengthMm * cropFactor;

    return AstroCalculatorResult(
      cropFactor: cropFactor,
      equivalentFocalLengthMm: equivalentFocalLengthMm,
      maxShutterSeconds: rule.divisor / equivalentFocalLengthMm,
    );
  }

  static double _cropFactor({
    required double sensorWidthMm,
    required double sensorHeightMm,
  }) {
    final sensorDiagonalMm = math.sqrt(
        (sensorWidthMm * sensorWidthMm) + (sensorHeightMm * sensorHeightMm));
    final fullFrameDiagonalMm = math.sqrt(
      (_fullFrameWidthMm * _fullFrameWidthMm) +
          (_fullFrameHeightMm * _fullFrameHeightMm),
    );
    return fullFrameDiagonalMm / sensorDiagonalMm;
  }
}
