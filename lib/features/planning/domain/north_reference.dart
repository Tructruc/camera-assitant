final class NorthReferenceBearing {
  const NorthReferenceBearing._();

  /// Converts a true bearing to magnetic bearing. Declination is east-positive.
  static double trueToMagnetic(double trueDegrees, double declinationDegrees) {
    if (!trueDegrees.isFinite ||
        !declinationDegrees.isFinite ||
        declinationDegrees < -90 ||
        declinationDegrees > 90) {
      throw const FormatException('Bearing and declination must be finite.');
    }
    return _normalize(trueDegrees - declinationDegrees);
  }

  static double magneticToTrue(
    double magneticDegrees,
    double declinationDegrees,
  ) {
    if (!magneticDegrees.isFinite ||
        !declinationDegrees.isFinite ||
        declinationDegrees < -90 ||
        declinationDegrees > 90) {
      throw const FormatException('Bearing and declination must be finite.');
    }
    return _normalize(magneticDegrees + declinationDegrees);
  }

  /// Difference from a magnetic device heading to a true-north target.
  static double deviceHeadingDelta({
    required double trueTargetDegrees,
    required double magneticHeadingDegrees,
    required double declinationDegrees,
  }) {
    final magneticTarget = trueToMagnetic(
      trueTargetDegrees,
      declinationDegrees,
    );
    if (!magneticHeadingDegrees.isFinite) {
      throw const FormatException('Device heading must be finite.');
    }
    final delta = _normalize(magneticTarget - magneticHeadingDegrees);
    return delta > 180 ? delta - 360 : delta;
  }

  static bool validDeclination(double degrees) =>
      degrees.isFinite && degrees >= -90 && degrees <= 90;
}

double _normalize(double value) => (value % 360 + 360) % 360;
