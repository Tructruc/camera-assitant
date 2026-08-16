import 'package:camera_assistant/domain/calculators/dof_calculator.dart';
import 'package:camera_assistant/features/dof/dof_state.dart';

class DofUseCase {
  const DofUseCase();

  DofCalculationState calculate(
    DofInput input, {
    bool live = false,
  }) {
    final focalLengthMm = input.focalLengthMm;
    final aperture = input.aperture;
    final subjectDistanceM = input.subjectDistanceM;

    if (focalLengthMm == null ||
        aperture == null ||
        subjectDistanceM == null ||
        focalLengthMm <= 0 ||
        aperture <= 0 ||
        subjectDistanceM <= 0) {
      return DofCalculationError(
        live ? null : 'Enter valid positive values.',
      );
    }

    final lens = input.lens;
    if (lens != null) {
      if (subjectDistanceM < lens.minFocusDistanceM) {
        return DofCalculationError(
          live
              ? null
              : 'Subject distance must be at least ${lens.minFocusDistanceM.toStringAsFixed(2)} m for ${lens.name}.',
        );
      }

      final minAtFocal = lens.minApertureAtFocal(focalLengthMm);
      if (aperture < minAtFocal || aperture > lens.maxAperture) {
        return DofCalculationError(
          live
              ? null
              : 'Aperture must stay within f/${minAtFocal.toStringAsFixed(1)} and f/${lens.maxAperture.toStringAsFixed(1)} at ${focalLengthMm.toStringAsFixed(0)}mm.',
        );
      }
    }

    final focalLengthM = focalLengthMm / 1000;
    final cocM = input.sensor.cocMm / 1000;

    final hyperfocalM = DOFCalculator.computeHyperfocal(
      focalLengthM,
      aperture,
      cocM,
    );
    final nearLimitM = DOFCalculator.computeNearLimit(
      hyperfocalM,
      subjectDistanceM,
      focalLengthM,
    );
    final farLimitM = DOFCalculator.computeFarLimit(
      hyperfocalM,
      subjectDistanceM,
      focalLengthM,
    );

    return DofCalculationSuccess(
      DofResult(
        hyperfocalM: hyperfocalM,
        nearLimitM: nearLimitM,
        subjectDistanceM: subjectDistanceM,
        farLimitM: farLimitM,
        totalDofM: DOFCalculator.computeDOF(nearLimitM, farLimitM),
      ),
    );
  }
}
