import 'package:camera_assistant/core/parsing/number_parser.dart';
import 'package:camera_assistant/domain/models/lens.dart';
import 'package:camera_assistant/domain/models/mount_preset.dart';
import 'package:camera_assistant/domain/models/sensor_preset.dart';
import 'package:camera_assistant/features/macro/macro_state.dart';
import 'package:camera_assistant/features/macro/macro_use_case.dart';

class MacroController {
  const MacroController({
    this.useCase = const MacroUseCase(),
  });

  final MacroUseCase useCase;

  List<MountPreset> resolveAvailableMounts(List<String> enabledMountIds) {
    final enabled = enabledMountIds.toSet();
    final mounts = mountPresets
        .where((mount) => enabled.isEmpty || enabled.contains(mount.id))
        .toList();
    return mounts.isEmpty ? mountPresets.toList() : mounts;
  }

  MountPreset? findMountById(String? mountId, List<MountPreset> mounts) {
    for (final mount in mounts) {
      if (mount.id == mountId) {
        return mount;
      }
    }
    return null;
  }

  String formatLensFocal(double focalMm) {
    return focalMm
        .toStringAsFixed(focalMm.truncateToDouble() == focalMm ? 0 : 1);
  }

  String clampAndFormatFocalForLens(Lens lens, double value) {
    final focal = value.clamp(lens.minFocalLengthMm, lens.maxFocalLengthMm);
    return formatLensFocal(focal);
  }

  String clampAndFormatApertureForLens(
    Lens lens, {
    required double focalMm,
    required double aperture,
  }) {
    final minAtFocal = lens.minApertureAtFocal(focalMm);
    final bounded = aperture.clamp(minAtFocal, lens.maxAperture);
    return bounded.toStringAsFixed(1);
  }

  double? parseTextNumber(String text) {
    return parseDouble(text);
  }

  ExtensionMacroCalculationState calculateExtensionFromForm({
    required String focalText,
    required String apertureText,
    required String minimumFocusDistanceText,
    required String extensionLengthText,
    required SensorPreset sensor,
  }) {
    return useCase.calculateExtension(
      ExtensionMacroInput(
        focalLengthMm: parseDouble(focalText),
        aperture: parseDouble(apertureText),
        minimumFocusDistanceM: parseDouble(minimumFocusDistanceText),
        extensionLengthMm: parseDouble(extensionLengthText),
        cocM: sensor.cocMm / 1000,
      ),
    );
  }

  ReverseMacroCalculationState calculateReverseFromForm({
    required String focalText,
    required String apertureText,
    required String extraExtensionText,
    required MountPreset? mount,
    required SensorPreset sensor,
  }) {
    return useCase.calculateReverse(
      ReverseMacroInput(
        focalLengthMm: parseDouble(focalText),
        aperture: parseDouble(apertureText),
        extraExtensionMm: parseDouble(extraExtensionText),
        mountRegisterDistanceMm: mount?.registerDistanceMm,
        cocM: sensor.cocMm / 1000,
      ),
    );
  }

  DualMacroCalculationState calculateDualFromForm({
    required String takingFocalText,
    required String takingApertureText,
    required String frontFocalText,
    required SensorPreset sensor,
  }) {
    return useCase.calculateDual(
      DualMacroInput(
        takingLensFocalLengthMm: parseDouble(takingFocalText),
        takingLensAperture: parseDouble(takingApertureText),
        frontLensFocalLengthMm: parseDouble(frontFocalText),
        cocM: sensor.cocMm / 1000,
      ),
    );
  }

  double suggestMacroSubjectDepth(double thicknessM) {
    if (!thicknessM.isFinite || thicknessM <= 0) {
      return 0.005;
    }
    return (thicknessM * 5).clamp(0.001, 0.05).toDouble();
  }
}
