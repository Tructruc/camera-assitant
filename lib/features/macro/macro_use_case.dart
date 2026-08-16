import 'package:camera_assistant/domain/calculators/macro_calculator.dart';
import 'package:camera_assistant/features/macro/macro_state.dart';

class MacroUseCase {
  const MacroUseCase();

  ExtensionMacroCalculationState calculateExtension(ExtensionMacroInput input) {
    final focal = input.focalLengthMm;
    final aperture = input.aperture;
    final minimumFocusDistance = input.minimumFocusDistanceM;
    final tubeLength = input.extensionLengthMm;

    if (focal == null ||
        aperture == null ||
        minimumFocusDistance == null ||
        tubeLength == null ||
        focal <= 0 ||
        aperture <= 0 ||
        minimumFocusDistance <= 0 ||
        tubeLength < 0) {
      return const MacroCalculationError(
        'Enter valid values. Tube length may be zero, all other values must be positive.',
      );
    }

    return MacroCalculationSuccess(
      MacroCalculator.calculateExtensionTube(
        focalLengthMm: focal,
        aperture: aperture,
        cocM: input.cocM,
        minimumFocusDistanceM: minimumFocusDistance,
        extensionLengthMm: tubeLength,
      ),
    );
  }

  ReverseMacroCalculationState calculateReverse(ReverseMacroInput input) {
    final focal = input.focalLengthMm;
    final aperture = input.aperture;
    final extraExtension = input.extraExtensionMm;
    final mountRegisterDistance = input.mountRegisterDistanceMm;

    if (focal == null ||
        aperture == null ||
        extraExtension == null ||
        mountRegisterDistance == null ||
        focal <= 0 ||
        aperture <= 0 ||
        extraExtension < 0) {
      return const MacroCalculationError(
        'Select a mount and enter valid focal length, aperture, and extra extension values.',
      );
    }

    return MacroCalculationSuccess(
      MacroCalculator.calculateReverseLens(
        focalLengthMm: focal,
        aperture: aperture,
        cocM: input.cocM,
        extensionBehindLensMm: mountRegisterDistance + extraExtension,
      ),
    );
  }

  DualMacroCalculationState calculateDual(DualMacroInput input) {
    final takingFocal = input.takingLensFocalLengthMm;
    final takingAperture = input.takingLensAperture;
    final frontFocal = input.frontLensFocalLengthMm;

    if (takingFocal == null ||
        takingAperture == null ||
        frontFocal == null ||
        takingFocal <= 0 ||
        takingAperture <= 0 ||
        frontFocal <= 0) {
      return const MacroCalculationError(
        'Enter valid taking-lens focal length, aperture, and reversed front-lens focal length values.',
      );
    }

    return MacroCalculationSuccess(
      MacroCalculator.calculateDualLensMacro(
        takingLensFocalLengthMm: takingFocal,
        takingLensAperture: takingAperture,
        cocM: input.cocM,
        frontLensFocalLengthMm: frontFocal,
      ),
    );
  }
}
