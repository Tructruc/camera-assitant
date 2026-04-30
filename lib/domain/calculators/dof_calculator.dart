class DOFCalculator {
  // Hyperfocal distance: H = f^2 / (N * c) + f
  static double computeHyperfocal(
      double focalLengthM, double aperture, double cocM) {
    return (focalLengthM * focalLengthM) / (aperture * cocM) + focalLengthM;
  }

  // Near limit: Dn = (H * s) / (H + (s - f))
  static double computeNearLimit(
    double hyperfocalM,
    double subjectDistanceM,
    double focalLengthM,
  ) {
    return (hyperfocalM * subjectDistanceM) /
        (hyperfocalM + (subjectDistanceM - focalLengthM));
  }

  // Far limit: Df = (H * s) / (H - (s - f))
  // Returns null if denominator is <= 0 (infinity case)
  static double? computeFarLimit(
    double hyperfocalM,
    double subjectDistanceM,
    double focalLengthM,
  ) {
    final denominator = hyperfocalM - (subjectDistanceM - focalLengthM);
    if (denominator <= 0) {
      return null;
    }
    return (hyperfocalM * subjectDistanceM) / denominator;
  }

  // Total DOF
  static double? computeDOF(double? nearLimitM, double? farLimitM) {
    if (nearLimitM == null || farLimitM == null) {
      return null;
    }
    return farLimitM - nearLimitM;
  }

  // Approximate subject-side depth at macro distances.
  static double? computeFocusPlaneThicknessFromMagnification(
    double aperture,
    double cocM,
    double magnification,
  ) {
    if (aperture <= 0 || cocM <= 0 || magnification <= 0) {
      return null;
    }
    return (2 * aperture * cocM * (1 + magnification)) /
        (magnification * magnification);
  }
}
