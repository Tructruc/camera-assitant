import 'dart:math' as math;

enum AstroShutterRule { rule500, rule400, rule300 }

extension AstroShutterRuleValues on AstroShutterRule {
  double get divisor => switch (this) {
        AstroShutterRule.rule500 => 500,
        AstroShutterRule.rule400 => 400,
        AstroShutterRule.rule300 => 300,
      };
}

enum AstroFramingTarget { moon, sun, star }

extension AstroFramingTargetValues on AstroFramingTarget {
  String get label => switch (this) {
        AstroFramingTarget.moon => 'Moon',
        AstroFramingTarget.sun => 'Sun',
        AstroFramingTarget.star => 'Star',
      };

  double get angularDiameterDeg => switch (this) {
        AstroFramingTarget.moon => 0.52,
        AstroFramingTarget.sun => 0.53,
        AstroFramingTarget.star => 0.0,
      };
}

enum AstroFramingOrientation { landscape, portrait }

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

class AstroFramingResult {
  const AstroFramingResult({
    required this.target,
    required this.orientation,
    required this.frameWidthMm,
    required this.frameHeightMm,
    required this.horizontalFovDeg,
    required this.verticalFovDeg,
    required this.diagonalFovDeg,
    required this.objectImageDiameterMm,
    required this.frameWidthCoverage,
    required this.frameHeightCoverage,
    required this.relativeMagnificationTo50mm,
  });

  final AstroFramingTarget target;
  final AstroFramingOrientation orientation;
  final double frameWidthMm;
  final double frameHeightMm;
  final double horizontalFovDeg;
  final double verticalFovDeg;
  final double diagonalFovDeg;
  final double objectImageDiameterMm;
  final double frameWidthCoverage;
  final double frameHeightCoverage;
  final double relativeMagnificationTo50mm;
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

  static AstroFramingResult calculateFraming({
    required double focalLengthMm,
    required double sensorWidthMm,
    required double sensorHeightMm,
    required AstroFramingTarget target,
    AstroFramingOrientation orientation = AstroFramingOrientation.landscape,
  }) {
    final frameWidthMm = orientation == AstroFramingOrientation.landscape
        ? sensorWidthMm
        : sensorHeightMm;
    final frameHeightMm = orientation == AstroFramingOrientation.landscape
        ? sensorHeightMm
        : sensorWidthMm;
    final objectImageDiameterMm =
        2 * focalLengthMm * math.tan(_degToRad(target.angularDiameterDeg) / 2);

    return AstroFramingResult(
      target: target,
      orientation: orientation,
      frameWidthMm: frameWidthMm,
      frameHeightMm: frameHeightMm,
      horizontalFovDeg: _angleOfViewDeg(frameWidthMm, focalLengthMm),
      verticalFovDeg: _angleOfViewDeg(frameHeightMm, focalLengthMm),
      diagonalFovDeg: _angleOfViewDeg(
        math.sqrt(
            (frameWidthMm * frameWidthMm) + (frameHeightMm * frameHeightMm)),
        focalLengthMm,
      ),
      objectImageDiameterMm: objectImageDiameterMm,
      frameWidthCoverage: objectImageDiameterMm / frameWidthMm,
      frameHeightCoverage: objectImageDiameterMm / frameHeightMm,
      relativeMagnificationTo50mm: focalLengthMm / 50.0,
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

  static double _angleOfViewDeg(double sensorDimMm, double focalLengthMm) {
    final radians = 2 * math.atan(sensorDimMm / (2 * focalLengthMm));
    return _radToDeg(radians);
  }

  static double _degToRad(double deg) => deg * math.pi / 180.0;
  static double _radToDeg(double rad) => rad * 180.0 / math.pi;
}
