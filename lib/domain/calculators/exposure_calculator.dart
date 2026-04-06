import 'dart:math' as math;

class ExposureCalculator {
  // Equivalent exposure constant: K = (N^2 / t) * (100 / ISO)
  static double computeK(double aperture, double shutter, double iso) {
    return (aperture * aperture / shutter) * (100 / iso);
  }

  // EV100: log2(N^2 / t)
  static double computeEV100(double aperture, double shutter) {
    return math.log(aperture * aperture / shutter) / math.ln2;
  }

  // Solve for shutter given aperture and ISO
  static double solveShutter(double k, double aperture, double iso) {
    return (aperture * aperture) * (100 / iso) / k;
  }

  // Solve for aperture given shutter and ISO
  static double solveAperture(double k, double shutter, double iso) {
    return math.sqrt(k * shutter * (iso / 100));
  }

  // Solve for ISO given aperture and shutter
  static double solveISO(double k, double aperture, double shutter) {
    return 100 * (aperture * aperture / shutter) / k;
  }
}
