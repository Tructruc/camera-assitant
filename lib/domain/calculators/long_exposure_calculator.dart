import 'dart:math' as math;

class LongExposureCalculator {
  // ND conversion: t2 = t1 * 2^stops
  static double convertByStops(double baseShutter, double stops) {
    return baseShutter * math.pow(2, stops).toDouble();
  }

  // ND conversion: t2 = t1 * factor
  static double convertByFactor(double baseShutter, double factor) {
    return baseShutter * factor;
  }

  // Physical light path: distance = speed * exposure
  static double computePhysicalPath(double speedMperS, double exposureSeconds) {
    return speedMperS * exposureSeconds;
  }

  // Sensor streak approximation: streak_mm = f_mm * distance_m / subjectDistance_m
  static double? computeSensorStreakMm(
    double focalLengthMm,
    double physicalPathM,
    double subjectDistanceM,
  ) {
    if (subjectDistanceM <= 0) {
      return null;
    }
    return focalLengthMm * physicalPathM / subjectDistanceM;
  }

  // Convert streak from mm to pixels
  static double? computeSensorStreakPx(double streakMm, double pixelPitchUm) {
    if (pixelPitchUm <= 0) {
      return null;
    }
    return streakMm / (pixelPitchUm / 1000.0);
  }
}
