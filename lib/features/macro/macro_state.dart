import 'package:camera_assistant/domain/calculators/macro_calculator.dart';

enum MacroToolMode { extensionTubes, reverseLens, dualLens }

class ExtensionMacroInput {
  const ExtensionMacroInput({
    required this.focalLengthMm,
    required this.aperture,
    required this.minimumFocusDistanceM,
    required this.extensionLengthMm,
    required this.cocM,
  });

  final double? focalLengthMm;
  final double? aperture;
  final double? minimumFocusDistanceM;
  final double? extensionLengthMm;
  final double cocM;
}

class ReverseMacroInput {
  const ReverseMacroInput({
    required this.focalLengthMm,
    required this.aperture,
    required this.extraExtensionMm,
    required this.mountRegisterDistanceMm,
    required this.cocM,
  });

  final double? focalLengthMm;
  final double? aperture;
  final double? extraExtensionMm;
  final double? mountRegisterDistanceMm;
  final double cocM;
}

class DualMacroInput {
  const DualMacroInput({
    required this.takingLensFocalLengthMm,
    required this.takingLensAperture,
    required this.frontLensFocalLengthMm,
    required this.cocM,
  });

  final double? takingLensFocalLengthMm;
  final double? takingLensAperture;
  final double? frontLensFocalLengthMm;
  final double cocM;
}

sealed class MacroCalculationState<T> {
  const MacroCalculationState();
}

class MacroCalculationSuccess<T> extends MacroCalculationState<T> {
  const MacroCalculationSuccess(this.result);

  final T result;
}

class MacroCalculationError<T> extends MacroCalculationState<T> {
  const MacroCalculationError(this.message);

  final String message;
}

typedef ExtensionMacroCalculationState
    = MacroCalculationState<ExtensionTubeResult>;
typedef ReverseMacroCalculationState = MacroCalculationState<ReverseLensResult>;
typedef DualMacroCalculationState = MacroCalculationState<DualLensMacroResult>;
