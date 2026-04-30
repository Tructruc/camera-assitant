import 'package:camera_assistant/domain/calculators/dof_calculator.dart';

class FocusStackingShot {
  const FocusStackingShot({
    required this.index,
    required this.focusDistanceM,
    required this.nearLimitM,
    required this.farLimitM,
    required this.stepFromPreviousM,
  });

  final int index;
  final double focusDistanceM;
  final double nearLimitM;
  final double? farLimitM;
  final double? stepFromPreviousM;
}

class FocusStackingResult {
  const FocusStackingResult({
    required this.targetNearM,
    required this.targetFarM,
    required this.overlapRatio,
    required this.hyperfocalM,
    required this.shots,
    required this.frameLimitReached,
  });

  final double targetNearM;
  final double targetFarM;
  final double overlapRatio;
  final double hyperfocalM;
  final List<FocusStackingShot> shots;
  final bool frameLimitReached;

  int get frameCount => shots.length;

  double get targetDepthM => targetFarM - targetNearM;

  double? get firstFocusDistanceM =>
      shots.isEmpty ? null : shots.first.focusDistanceM;

  double? get lastFocusDistanceM =>
      shots.isEmpty ? null : shots.last.focusDistanceM;

  double? get coveredFarM =>
      shots.isEmpty ? null : (shots.last.farLimitM ?? double.infinity);

  bool get coversEntireRange {
    final coveredFar = coveredFarM;
    if (coveredFar == null) {
      return false;
    }
    return !frameLimitReached && coveredFar >= targetFarM;
  }

  double? get averageFocusStepM {
    final steps = shots
        .map((shot) => shot.stepFromPreviousM)
        .whereType<double>()
        .toList();
    if (steps.isEmpty) {
      return null;
    }
    return steps.reduce((a, b) => a + b) / steps.length;
  }
}

class MacroFocusStackingShot {
  const MacroFocusStackingShot({
    required this.index,
    required this.focusOffsetM,
    required this.startOffsetM,
    required this.endOffsetM,
    required this.stepFromPreviousM,
  });

  final int index;
  final double focusOffsetM;
  final double startOffsetM;
  final double endOffsetM;
  final double? stepFromPreviousM;
}

class MacroFocusStackingResult {
  const MacroFocusStackingResult({
    required this.subjectDepthM,
    required this.overlapRatio,
    required this.planningMagnification,
    required this.focusPlaneThicknessM,
    required this.recommendedRailStepM,
    required this.shots,
  });

  final double subjectDepthM;
  final double overlapRatio;
  final double planningMagnification;
  final double focusPlaneThicknessM;
  final double recommendedRailStepM;
  final List<MacroFocusStackingShot> shots;

  int get frameCount => shots.length;
}

class FocusStackingCalculator {
  static const int maxFrames = 200;

  static FocusStackingResult plan({
    required double focalLengthMm,
    required double aperture,
    required double cocM,
    required double nearestSubjectDistanceM,
    required double farthestSubjectDistanceM,
    required double overlapRatio,
  }) {
    final focalLengthM = focalLengthMm / 1000;
    final hyperfocalM = DOFCalculator.computeHyperfocal(
      focalLengthM,
      aperture,
      cocM,
    );

    var targetNearM = nearestSubjectDistanceM;
    final shots = <FocusStackingShot>[];
    var frameLimitReached = true;

    for (var index = 0; index < maxFrames; index++) {
      final focusDistanceM = _focusDistanceForNearLimit(
        hyperfocalM: hyperfocalM,
        nearLimitM: targetNearM,
        focalLengthM: focalLengthM,
      );
      final nearLimitM = DOFCalculator.computeNearLimit(
        hyperfocalM,
        focusDistanceM,
        focalLengthM,
      );
      final farLimitM = DOFCalculator.computeFarLimit(
        hyperfocalM,
        focusDistanceM,
        focalLengthM,
      );

      shots.add(
        FocusStackingShot(
          index: index + 1,
          focusDistanceM: focusDistanceM,
          nearLimitM: nearLimitM,
          farLimitM: farLimitM,
          stepFromPreviousM:
              shots.isEmpty ? null : focusDistanceM - shots.last.focusDistanceM,
        ),
      );

      if (farLimitM == null || farLimitM >= farthestSubjectDistanceM) {
        frameLimitReached = false;
        break;
      }

      final coverageDepthM = farLimitM - nearLimitM;
      final nextTargetNearM = farLimitM - (coverageDepthM * overlapRatio);
      if (nextTargetNearM <= targetNearM) {
        break;
      }
      targetNearM = nextTargetNearM;
    }

    return FocusStackingResult(
      targetNearM: nearestSubjectDistanceM,
      targetFarM: farthestSubjectDistanceM,
      overlapRatio: overlapRatio,
      hyperfocalM: hyperfocalM,
      shots: shots,
      frameLimitReached: frameLimitReached,
    );
  }

  static double _focusDistanceForNearLimit({
    required double hyperfocalM,
    required double nearLimitM,
    required double focalLengthM,
  }) {
    if (nearLimitM >= hyperfocalM) {
      return nearLimitM;
    }

    return (nearLimitM * (hyperfocalM - focalLengthM)) /
        (hyperfocalM - nearLimitM);
  }
}

class MacroFocusStackingCalculator {
  static const int maxFrames = 200;

  static MacroFocusStackingResult plan({
    required double aperture,
    required double cocM,
    required double magnification,
    required double subjectDepthM,
    required double overlapRatio,
  }) {
    final focusPlaneThicknessM =
        DOFCalculator.computeFocusPlaneThicknessFromMagnification(
              aperture,
              cocM,
              magnification,
            ) ??
            0;
    final recommendedRailStepM = focusPlaneThicknessM * (1 - overlapRatio);

    final shots = <MacroFocusStackingShot>[];
    var coveredDepthM = 0.0;
    var previousFocusOffsetM = 0.0;

    for (var index = 0; index < maxFrames; index++) {
      final startOffsetM = index == 0 ? 0.0 : coveredDepthM;
      final endOffsetM = (startOffsetM + focusPlaneThicknessM)
          .clamp(0.0, subjectDepthM)
          .toDouble();
      final focusOffsetM = (startOffsetM + endOffsetM) / 2;

      shots.add(
        MacroFocusStackingShot(
          index: index + 1,
          focusOffsetM: focusOffsetM,
          startOffsetM: startOffsetM,
          endOffsetM: endOffsetM,
          stepFromPreviousM:
              index == 0 ? null : focusOffsetM - previousFocusOffsetM,
        ),
      );

      if (endOffsetM >= subjectDepthM) {
        break;
      }

      previousFocusOffsetM = focusOffsetM;
      coveredDepthM = startOffsetM + recommendedRailStepM;
      if (recommendedRailStepM <= 0) {
        break;
      }
    }

    return MacroFocusStackingResult(
      subjectDepthM: subjectDepthM,
      overlapRatio: overlapRatio,
      planningMagnification: magnification,
      focusPlaneThicknessM: focusPlaneThicknessM,
      recommendedRailStepM: recommendedRailStepM,
      shots: shots,
    );
  }
}
