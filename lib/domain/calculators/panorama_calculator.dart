import 'dart:math' as math;

enum PanoramaOrientation { landscape, portrait }

class PanoramaCalculatorResult {
  const PanoramaCalculatorResult({
    required this.frameHorizontalFovDeg,
    required this.frameVerticalFovDeg,
    required this.horizontalAdvanceDeg,
    required this.verticalAdvanceDeg,
    required this.horizontalFrames,
    required this.verticalFrames,
    required this.totalFrames,
    required this.stitchedHorizontalFovDeg,
    required this.stitchedVerticalFovDeg,
  });

  final double frameHorizontalFovDeg;
  final double frameVerticalFovDeg;
  final double horizontalAdvanceDeg;
  final double verticalAdvanceDeg;
  final int horizontalFrames;
  final int verticalFrames;
  final int totalFrames;
  final double stitchedHorizontalFovDeg;
  final double stitchedVerticalFovDeg;
}

class PanoramaCalculator {
  static PanoramaCalculatorResult calculate({
    required double focalLengthMm,
    required double sensorWidthMm,
    required double sensorHeightMm,
    required PanoramaOrientation orientation,
    required double targetHorizontalFovDeg,
    required double targetVerticalFovDeg,
    required double overlapPercent,
  }) {
    final frameWidthMm = orientation == PanoramaOrientation.landscape
        ? sensorWidthMm
        : sensorHeightMm;
    final frameHeightMm = orientation == PanoramaOrientation.landscape
        ? sensorHeightMm
        : sensorWidthMm;

    final frameHorizontalFovDeg = _angleOfViewDeg(frameWidthMm, focalLengthMm);
    final frameVerticalFovDeg = _angleOfViewDeg(frameHeightMm, focalLengthMm);
    final overlapFactor = 1 - (overlapPercent / 100);
    final horizontalAdvanceDeg = frameHorizontalFovDeg * overlapFactor;
    final verticalAdvanceDeg = frameVerticalFovDeg * overlapFactor;

    final horizontalFrames = _framesNeeded(
      frameFovDeg: frameHorizontalFovDeg,
      targetFovDeg: targetHorizontalFovDeg,
      advanceDeg: horizontalAdvanceDeg,
    );
    final verticalFrames = _framesNeeded(
      frameFovDeg: frameVerticalFovDeg,
      targetFovDeg: targetVerticalFovDeg,
      advanceDeg: verticalAdvanceDeg,
    );

    return PanoramaCalculatorResult(
      frameHorizontalFovDeg: frameHorizontalFovDeg,
      frameVerticalFovDeg: frameVerticalFovDeg,
      horizontalAdvanceDeg: horizontalAdvanceDeg,
      verticalAdvanceDeg: verticalAdvanceDeg,
      horizontalFrames: horizontalFrames,
      verticalFrames: verticalFrames,
      totalFrames: horizontalFrames * verticalFrames,
      stitchedHorizontalFovDeg: _stitchedCoverageDeg(
          frameHorizontalFovDeg, horizontalAdvanceDeg, horizontalFrames),
      stitchedVerticalFovDeg: _stitchedCoverageDeg(
          frameVerticalFovDeg, verticalAdvanceDeg, verticalFrames),
    );
  }

  static double _angleOfViewDeg(double sensorDimMm, double focalLengthMm) {
    final radians = 2 * math.atan(sensorDimMm / (2 * focalLengthMm));
    return radians * 180 / math.pi;
  }

  static int _framesNeeded({
    required double frameFovDeg,
    required double targetFovDeg,
    required double advanceDeg,
  }) {
    if (targetFovDeg <= frameFovDeg) {
      return 1;
    }
    return 1 + ((targetFovDeg - frameFovDeg) / advanceDeg).ceil();
  }

  static double _stitchedCoverageDeg(
    double frameFovDeg,
    double advanceDeg,
    int frames,
  ) {
    return frameFovDeg + (math.max(frames - 1, 0) * advanceDeg);
  }
}
