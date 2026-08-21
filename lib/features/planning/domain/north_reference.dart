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
}

double _normalize(double value) => (value % 360 + 360) % 360;
