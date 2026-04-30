import 'package:camera_assistant/domain/calculators/dof_calculator.dart';

import 'dart:math' as math;

class ExtensionTubeResult {
  const ExtensionTubeResult({
    required this.nativeMaximumMagnification,
    required this.addedMagnification,
    required this.minimumMagnification,
    required this.maximumMagnification,
    required this.closestFocusDistanceM,
    required this.farthestFocusDistanceM,
    required this.effectiveApertureAtFarthestFocus,
    required this.effectiveApertureAtClosestFocus,
    required this.lightLossStopsAtFarthestFocus,
    required this.lightLossStopsAtClosestFocus,
    required this.exposureFactorAtFarthestFocus,
    required this.exposureFactorAtClosestFocus,
    required this.focusPlaneThicknessAtFarthestFocusM,
    required this.focusPlaneThicknessAtClosestFocusM,
  });

  final double nativeMaximumMagnification;
  final double addedMagnification;
  final double minimumMagnification;
  final double maximumMagnification;
  final double closestFocusDistanceM;
  final double farthestFocusDistanceM;
  final double effectiveApertureAtFarthestFocus;
  final double effectiveApertureAtClosestFocus;
  final double lightLossStopsAtFarthestFocus;
  final double lightLossStopsAtClosestFocus;
  final double exposureFactorAtFarthestFocus;
  final double exposureFactorAtClosestFocus;
  final double focusPlaneThicknessAtFarthestFocusM;
  final double focusPlaneThicknessAtClosestFocusM;
}

class ReverseLensResult {
  const ReverseLensResult({
    required this.magnification,
    required this.effectiveAperture,
    required this.lightLossStops,
    required this.exposureFactor,
    required this.subjectDistanceFromLensPlaneM,
    required this.subjectDistanceFromSensorPlaneM,
    required this.focusPlaneThicknessM,
  });

  final double magnification;
  final double effectiveAperture;
  final double lightLossStops;
  final double exposureFactor;
  final double subjectDistanceFromLensPlaneM;
  final double subjectDistanceFromSensorPlaneM;
  final double focusPlaneThicknessM;
}

class DualLensMacroResult {
  const DualLensMacroResult({
    required this.magnification,
    required this.effectiveAperture,
    required this.lightLossStops,
    required this.exposureFactor,
    required this.workingDistanceFromFrontLensM,
    required this.focusPlaneThicknessM,
  });

  final double magnification;
  final double effectiveAperture;
  final double lightLossStops;
  final double exposureFactor;
  final double workingDistanceFromFrontLensM;
  final double focusPlaneThicknessM;
}

class MacroCalculator {
  static ExtensionTubeResult calculateExtensionTube({
    required double focalLengthMm,
    required double aperture,
    required double cocM,
    required double minimumFocusDistanceM,
    required double extensionLengthMm,
  }) {
    final nativeMagnification = estimateMagnificationFromSensorDistance(
      focalLengthMm: focalLengthMm,
      sensorToSubjectDistanceMm: minimumFocusDistanceM * 1000,
    );
    final addedMagnification = extensionLengthMm / focalLengthMm;
    final minimumMagnification = addedMagnification;
    final maximumMagnification = nativeMagnification + addedMagnification;

    return ExtensionTubeResult(
      nativeMaximumMagnification: nativeMagnification,
      addedMagnification: addedMagnification,
      minimumMagnification: minimumMagnification,
      maximumMagnification: maximumMagnification,
      closestFocusDistanceM: sensorDistanceFromMagnification(
            focalLengthMm: focalLengthMm,
            magnification: maximumMagnification,
          ) /
          1000,
      farthestFocusDistanceM: minimumMagnification <= 0
          ? double.infinity
          : sensorDistanceFromMagnification(
                focalLengthMm: focalLengthMm,
                magnification: minimumMagnification,
              ) /
              1000,
      effectiveApertureAtFarthestFocus: effectiveAperture(
        aperture: aperture,
        magnification: minimumMagnification,
      ),
      effectiveApertureAtClosestFocus: effectiveAperture(
        aperture: aperture,
        magnification: maximumMagnification,
      ),
      lightLossStopsAtFarthestFocus: lightLossStops(minimumMagnification),
      lightLossStopsAtClosestFocus: lightLossStops(maximumMagnification),
      exposureFactorAtFarthestFocus: exposureFactor(minimumMagnification),
      exposureFactorAtClosestFocus: exposureFactor(maximumMagnification),
      focusPlaneThicknessAtFarthestFocusM:
          DOFCalculator.computeFocusPlaneThicknessFromMagnification(
                aperture,
                cocM,
                minimumMagnification,
              ) ??
              double.infinity,
      focusPlaneThicknessAtClosestFocusM:
          DOFCalculator.computeFocusPlaneThicknessFromMagnification(
                aperture,
                cocM,
                maximumMagnification,
              ) ??
              double.infinity,
    );
  }

  static ReverseLensResult calculateReverseLens({
    required double focalLengthMm,
    required double aperture,
    required double cocM,
    required double extensionBehindLensMm,
  }) {
    final magnification = extensionBehindLensMm / focalLengthMm;

    return ReverseLensResult(
      magnification: magnification,
      effectiveAperture: effectiveAperture(
        aperture: aperture,
        magnification: magnification,
      ),
      lightLossStops: lightLossStops(magnification),
      exposureFactor: exposureFactor(magnification),
      subjectDistanceFromLensPlaneM: subjectDistanceFromLensPlane(
            focalLengthMm: focalLengthMm,
            magnification: magnification,
          ) /
          1000,
      subjectDistanceFromSensorPlaneM: sensorDistanceFromMagnification(
            focalLengthMm: focalLengthMm,
            magnification: magnification,
          ) /
          1000,
      focusPlaneThicknessM:
          DOFCalculator.computeFocusPlaneThicknessFromMagnification(
                aperture,
                cocM,
                magnification,
              ) ??
              double.infinity,
    );
  }

  static DualLensMacroResult calculateDualLensMacro({
    required double takingLensFocalLengthMm,
    required double takingLensAperture,
    required double cocM,
    required double frontLensFocalLengthMm,
  }) {
    final magnification = takingLensFocalLengthMm / frontLensFocalLengthMm;

    return DualLensMacroResult(
      magnification: magnification,
      effectiveAperture: effectiveAperture(
        aperture: takingLensAperture,
        magnification: magnification,
      ),
      lightLossStops: lightLossStops(magnification),
      exposureFactor: exposureFactor(magnification),
      workingDistanceFromFrontLensM: frontLensFocalLengthMm / 1000,
      focusPlaneThicknessM:
          DOFCalculator.computeFocusPlaneThicknessFromMagnification(
                takingLensAperture,
                cocM,
                magnification,
              ) ??
              double.infinity,
    );
  }

  static double estimateMagnificationFromSensorDistance({
    required double focalLengthMm,
    required double sensorToSubjectDistanceMm,
  }) {
    final normalizedDistance =
        math.max(sensorToSubjectDistanceMm / focalLengthMm - 2, 2.0);
    final discriminant =
        math.max(normalizedDistance * normalizedDistance - 4, 0.0);
    return (normalizedDistance - math.sqrt(discriminant)) / 2;
  }

  static double sensorDistanceFromMagnification({
    required double focalLengthMm,
    required double magnification,
  }) {
    if (magnification <= 0) {
      return double.infinity;
    }
    return focalLengthMm * (2 + magnification + (1 / magnification));
  }

  static double subjectDistanceFromLensPlane({
    required double focalLengthMm,
    required double magnification,
  }) {
    if (magnification <= 0) {
      return double.infinity;
    }
    return focalLengthMm * (1 + (1 / magnification));
  }

  static double effectiveAperture({
    required double aperture,
    required double magnification,
  }) {
    return aperture * (1 + magnification);
  }

  static double lightLossStops(double magnification) {
    return 2 * math.log(1 + magnification) / math.ln2;
  }

  static double exposureFactor(double magnification) {
    final factor = 1 + magnification;
    return factor * factor;
  }
}
