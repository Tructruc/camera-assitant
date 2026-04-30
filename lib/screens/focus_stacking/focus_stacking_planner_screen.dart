import 'package:camera_assistant/data/database/lens_database.dart';
import 'package:camera_assistant/domain/calculators/focus_stacking_calculator.dart';
import 'package:camera_assistant/domain/calculators/macro_calculator.dart';
import 'package:camera_assistant/domain/models/app_settings.dart';
import 'package:camera_assistant/domain/models/lens.dart';
import 'package:camera_assistant/domain/models/mount_preset.dart';
import 'package:camera_assistant/domain/models/sensor_preset.dart';
import 'package:camera_assistant/shared/utils/formatters.dart';
import 'package:camera_assistant/shared/widgets/info_metric_tile.dart';
import 'package:camera_assistant/shared/widgets/lens_value_slider.dart';
import 'package:camera_assistant/shared/widgets/num_field.dart';
import 'package:camera_assistant/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';

enum FocusStackingSetupMode { standard, extensionTubes, reverseLens, dualLens }

enum FocusStackingMethod { refocusLens, moveCamera }

class FocusStackingPreset {
  const FocusStackingPreset._({
    required this.mode,
    this.method,
    this.lensId,
    this.sensorCocMm,
    this.focalMm,
    this.aperture,
    this.nearDistanceM,
    this.farDistanceM,
    this.overlapPercent,
    this.minimumFocusDistanceM,
    this.extensionLengthMm,
    this.mountId,
    this.extraExtensionMm,
    this.takingLensFocalMm,
    this.frontLensFocalMm,
    this.subjectDepthM,
  });

  const FocusStackingPreset.standard({
    FocusStackingMethod? method,
    int? lensId,
    double? sensorCocMm,
    double? focalMm,
    double? aperture,
    double? nearDistanceM,
    double? farDistanceM,
    double? overlapPercent,
  }) : this._(
          mode: FocusStackingSetupMode.standard,
          method: method,
          lensId: lensId,
          sensorCocMm: sensorCocMm,
          focalMm: focalMm,
          aperture: aperture,
          nearDistanceM: nearDistanceM,
          farDistanceM: farDistanceM,
          overlapPercent: overlapPercent,
        );

  const FocusStackingPreset.extension({
    FocusStackingMethod? method,
    int? lensId,
    double? sensorCocMm,
    double? focalMm,
    double? aperture,
    double? minimumFocusDistanceM,
    double? extensionLengthMm,
    double? subjectDepthM,
    double? overlapPercent,
  }) : this._(
          mode: FocusStackingSetupMode.extensionTubes,
          method: method,
          lensId: lensId,
          sensorCocMm: sensorCocMm,
          focalMm: focalMm,
          aperture: aperture,
          minimumFocusDistanceM: minimumFocusDistanceM,
          extensionLengthMm: extensionLengthMm,
          subjectDepthM: subjectDepthM,
          overlapPercent: overlapPercent,
        );

  const FocusStackingPreset.reverse({
    FocusStackingMethod? method,
    double? sensorCocMm,
    double? focalMm,
    double? aperture,
    String? mountId,
    double? extraExtensionMm,
    double? subjectDepthM,
    double? overlapPercent,
  }) : this._(
          mode: FocusStackingSetupMode.reverseLens,
          method: method,
          sensorCocMm: sensorCocMm,
          focalMm: focalMm,
          aperture: aperture,
          mountId: mountId,
          extraExtensionMm: extraExtensionMm,
          subjectDepthM: subjectDepthM,
          overlapPercent: overlapPercent,
        );

  const FocusStackingPreset.dual({
    FocusStackingMethod? method,
    double? sensorCocMm,
    double? takingLensFocalMm,
    double? aperture,
    double? frontLensFocalMm,
    double? subjectDepthM,
    double? overlapPercent,
  }) : this._(
          mode: FocusStackingSetupMode.dualLens,
          method: method,
          sensorCocMm: sensorCocMm,
          takingLensFocalMm: takingLensFocalMm,
          aperture: aperture,
          frontLensFocalMm: frontLensFocalMm,
          subjectDepthM: subjectDepthM,
          overlapPercent: overlapPercent,
        );

  final FocusStackingSetupMode mode;
  final FocusStackingMethod? method;
  final int? lensId;
  final double? sensorCocMm;
  final double? focalMm;
  final double? aperture;
  final double? nearDistanceM;
  final double? farDistanceM;
  final double? overlapPercent;
  final double? minimumFocusDistanceM;
  final double? extensionLengthMm;
  final String? mountId;
  final double? extraExtensionMm;
  final double? takingLensFocalMm;
  final double? frontLensFocalMm;
  final double? subjectDepthM;
}

class FocusStackingPlannerScreen extends StatefulWidget {
  const FocusStackingPlannerScreen({
    super.key,
    this.settings = const AppSettings(),
    this.initialPreset,
  });

  final AppSettings settings;
  final FocusStackingPreset? initialPreset;

  @override
  State<FocusStackingPlannerScreen> createState() =>
      _FocusStackingPlannerScreenState();
}

class _FocusStackingPlannerScreenState
    extends State<FocusStackingPlannerScreen> {
  final _db = LensDatabase.instance;

  final _standardFocalMm = TextEditingController(text: '100');
  final _standardAperture = TextEditingController(text: '5.6');
  final _standardNearDistanceM = TextEditingController(text: '0.30');
  final _standardFarDistanceM = TextEditingController(text: '0.32');

  final _extensionFocalMm = TextEditingController(text: '50');
  final _extensionAperture = TextEditingController(text: '2.8');
  final _extensionMinFocusM = TextEditingController(text: '0.45');
  final _extensionTubeMm = TextEditingController(text: '25');
  final _extensionNearDistanceM = TextEditingController(text: '0.21');
  final _extensionFarDistanceM = TextEditingController(text: '0.23');
  final _extensionSubjectDepthM = TextEditingController(text: '0.001');

  final _reverseFocalMm = TextEditingController(text: '28');
  final _reverseAperture = TextEditingController(text: '2.8');
  final _reverseExtraExtensionMm = TextEditingController(text: '0');
  final _reverseSubjectDepthM = TextEditingController(text: '0.001');

  final _dualTakingFocalMm = TextEditingController(text: '100');
  final _dualTakingAperture = TextEditingController(text: '5.6');
  final _dualFrontFocalMm = TextEditingController(text: '50');
  final _dualSubjectDepthM = TextEditingController(text: '0.001');

  final _overlapPercent = TextEditingController(text: '30');

  List<Lens> _lenses = const [];
  int? _selectedLensId;
  String? _selectedMountId;
  late SensorPreset _selectedSensor;
  late FocusStackingSetupMode _mode;
  late FocusStackingMethod _method;

  String? _errorMessage;
  FocusStackingResult? _standardResult;
  MacroFocusStackingResult? _macroResult;
  String? _macroResultLabel;
  String? _macroContextLabel;
  String? _macroCoverageLabel;

  List<SensorPreset> get _availableSensors =>
      resolveEnabledSensorPresets(widget.settings.enabledSensorIds);

  Lens? get _selectedLens {
    if (_selectedLensId == null) {
      return null;
    }
    for (final lens in _lenses) {
      if (lens.id == _selectedLensId) {
        return lens;
      }
    }
    return null;
  }

  MountPreset? get _selectedMount {
    for (final mount in mountPresets) {
      if (mount.id == _selectedMountId) {
        return mount;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final preset = widget.initialPreset;
    _mode = preset?.mode ?? FocusStackingSetupMode.standard;
    _method = _resolveInitialMethod(preset);
    _selectedSensor = _resolveSensorPreset(preset?.sensorCocMm);
    _selectedMountId = preset?.mountId ?? mountPresets.first.id;
    _applyInitialPreset(preset);
    _loadLenses();
  }

  @override
  void dispose() {
    _standardFocalMm.dispose();
    _standardAperture.dispose();
    _standardNearDistanceM.dispose();
    _standardFarDistanceM.dispose();
    _extensionFocalMm.dispose();
    _extensionAperture.dispose();
    _extensionMinFocusM.dispose();
    _extensionTubeMm.dispose();
    _extensionNearDistanceM.dispose();
    _extensionFarDistanceM.dispose();
    _extensionSubjectDepthM.dispose();
    _reverseFocalMm.dispose();
    _reverseAperture.dispose();
    _reverseExtraExtensionMm.dispose();
    _reverseSubjectDepthM.dispose();
    _dualTakingFocalMm.dispose();
    _dualTakingAperture.dispose();
    _dualFrontFocalMm.dispose();
    _dualSubjectDepthM.dispose();
    _overlapPercent.dispose();
    super.dispose();
  }

  SensorPreset _resolveSensorPreset(double? cocMm) {
    final availableSensors = _availableSensors;
    if (cocMm == null) {
      return availableSensors.first;
    }
    for (final preset in availableSensors) {
      if ((preset.cocMm - cocMm).abs() < 0.0001) {
        return preset;
      }
    }
    return availableSensors.first;
  }

  FocusStackingMethod _resolveInitialMethod(FocusStackingPreset? preset) {
    if (preset?.method != null) {
      return preset!.method!;
    }
    return switch (preset?.mode) {
      FocusStackingSetupMode.extensionTubes => FocusStackingMethod.moveCamera,
      FocusStackingSetupMode.reverseLens => FocusStackingMethod.moveCamera,
      FocusStackingSetupMode.dualLens => FocusStackingMethod.moveCamera,
      _ => FocusStackingMethod.refocusLens,
    };
  }

  bool get _supportsRefocus =>
      _mode == FocusStackingSetupMode.standard ||
      _mode == FocusStackingSetupMode.extensionTubes;

  void _applyInitialPreset(FocusStackingPreset? preset) {
    if (preset == null) {
      return;
    }

    _selectedLensId = preset.lensId;
    if (preset.overlapPercent != null) {
      _overlapPercent.text = preset.overlapPercent!.toStringAsFixed(0);
    }

    switch (preset.mode) {
      case FocusStackingSetupMode.standard:
        if (preset.focalMm != null) {
          _standardFocalMm.text = _formatInput(preset.focalMm!);
        }
        if (preset.aperture != null) {
          _standardAperture.text = preset.aperture!.toStringAsFixed(1);
        }
        if (preset.nearDistanceM != null) {
          _standardNearDistanceM.text =
              preset.nearDistanceM!.toStringAsFixed(2);
        }
        if (preset.farDistanceM != null) {
          _standardFarDistanceM.text = preset.farDistanceM!.toStringAsFixed(2);
        }
        return;
      case FocusStackingSetupMode.extensionTubes:
        if (preset.focalMm != null) {
          _extensionFocalMm.text = _formatInput(preset.focalMm!);
        }
        if (preset.aperture != null) {
          _extensionAperture.text = preset.aperture!.toStringAsFixed(1);
        }
        if (preset.minimumFocusDistanceM != null) {
          _extensionMinFocusM.text =
              preset.minimumFocusDistanceM!.toStringAsFixed(2);
        }
        if (preset.extensionLengthMm != null) {
          _extensionTubeMm.text = _formatInput(preset.extensionLengthMm!);
        }
        if (preset.nearDistanceM != null) {
          _extensionNearDistanceM.text =
              preset.nearDistanceM!.toStringAsFixed(2);
        }
        if (preset.farDistanceM != null) {
          _extensionFarDistanceM.text = preset.farDistanceM!.toStringAsFixed(2);
        }
        if (preset.subjectDepthM != null) {
          _extensionSubjectDepthM.text =
              preset.subjectDepthM!.toStringAsFixed(4);
        }
        return;
      case FocusStackingSetupMode.reverseLens:
        if (preset.focalMm != null) {
          _reverseFocalMm.text = _formatInput(preset.focalMm!);
        }
        if (preset.aperture != null) {
          _reverseAperture.text = preset.aperture!.toStringAsFixed(1);
        }
        if (preset.extraExtensionMm != null) {
          _reverseExtraExtensionMm.text =
              _formatInput(preset.extraExtensionMm!);
        }
        if (preset.subjectDepthM != null) {
          _reverseSubjectDepthM.text = preset.subjectDepthM!.toStringAsFixed(4);
        }
        return;
      case FocusStackingSetupMode.dualLens:
        if (preset.takingLensFocalMm != null) {
          _dualTakingFocalMm.text = _formatInput(preset.takingLensFocalMm!);
        }
        if (preset.aperture != null) {
          _dualTakingAperture.text = preset.aperture!.toStringAsFixed(1);
        }
        if (preset.frontLensFocalMm != null) {
          _dualFrontFocalMm.text = _formatInput(preset.frontLensFocalMm!);
        }
        if (preset.subjectDepthM != null) {
          _dualSubjectDepthM.text = preset.subjectDepthM!.toStringAsFixed(4);
        }
        return;
    }
  }

  String _formatInput(double value) {
    return value.truncateToDouble() == value
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }

  Future<void> _loadLenses() async {
    final lenses = await _db.getLenses();
    if (!mounted) {
      return;
    }

    final selectedExists = lenses.any((lens) => lens.id == _selectedLensId);
    setState(() {
      _lenses = lenses;
      if (!selectedExists) {
        _selectedLensId = null;
      }
    });

    if (widget.initialPreset != null) {
      _calculate();
    }
  }

  void _clearSelectedLens() {
    setState(() {
      _selectedLensId = null;
      _errorMessage = null;
      _standardResult = null;
      _macroResult = null;
      _macroResultLabel = null;
      _macroContextLabel = null;
      _macroCoverageLabel = null;
    });
  }

  void _applyLensToCurrentMode(Lens lens) {
    switch (_mode) {
      case FocusStackingSetupMode.standard:
        final focal = lens.minFocalLengthMm;
        final aperture = lens.minApertureAtFocal(focal);
        setState(() {
          _selectedLensId = lens.id;
          _standardFocalMm.text = _formatInput(focal);
          _standardAperture.text = aperture.toStringAsFixed(1);
        });
        return;
      case FocusStackingSetupMode.extensionTubes:
        final focal = lens.minFocalLengthMm;
        final aperture = lens.minApertureAtFocal(focal);
        setState(() {
          _selectedLensId = lens.id;
          _extensionFocalMm.text = _formatInput(focal);
          _extensionAperture.text = aperture.toStringAsFixed(1);
          _extensionMinFocusM.text = lens.minFocusDistanceM.toStringAsFixed(2);
        });
        return;
      case FocusStackingSetupMode.reverseLens:
        final focal = lens.minFocalLengthMm;
        final aperture = lens.minApertureAtFocal(focal);
        final mountPreset = resolveMountPreset(lens.mount);
        setState(() {
          _selectedLensId = lens.id;
          if (mountPreset != null) {
            _selectedMountId = mountPreset.id;
          }
          _reverseFocalMm.text = _formatInput(focal);
          _reverseAperture.text = aperture.toStringAsFixed(1);
        });
        return;
      case FocusStackingSetupMode.dualLens:
        final focal = lens.maxFocalLengthMm;
        final aperture = lens.minApertureAtFocal(focal);
        setState(() {
          _selectedLensId = lens.id;
          _dualTakingFocalMm.text = _formatInput(focal);
          _dualTakingAperture.text = aperture.toStringAsFixed(1);
        });
        return;
    }
  }

  void _updateStandardLensFocal(double value) {
    final lens = _selectedLens;
    if (lens == null) {
      return;
    }
    final focal = value.clamp(lens.minFocalLengthMm, lens.maxFocalLengthMm);
    final minAtFocal = lens.minApertureAtFocal(focal);
    final currentAperture = parseDouble(_standardAperture.text) ?? minAtFocal;

    setState(() {
      _standardFocalMm.text = _formatInput(focal);
      if (currentAperture < minAtFocal) {
        _standardAperture.text = minAtFocal.toStringAsFixed(1);
      }
    });
  }

  void _updateStandardLensAperture(double value) {
    final lens = _selectedLens;
    if (lens == null) {
      return;
    }
    final focal = parseDouble(_standardFocalMm.text) ?? lens.minFocalLengthMm;
    final minAtFocal = lens.minApertureAtFocal(focal);
    final aperture = value.clamp(minAtFocal, lens.maxAperture);

    setState(() {
      _standardAperture.text = aperture.toStringAsFixed(1);
    });
  }

  void _updateExtensionLensFocal(double value) {
    final lens = _selectedLens;
    if (lens == null) {
      return;
    }
    final focal = value.clamp(lens.minFocalLengthMm, lens.maxFocalLengthMm);
    final minAtFocal = lens.minApertureAtFocal(focal);
    final currentAperture = parseDouble(_extensionAperture.text) ?? minAtFocal;

    setState(() {
      _extensionFocalMm.text = _formatInput(focal);
      if (currentAperture < minAtFocal) {
        _extensionAperture.text = minAtFocal.toStringAsFixed(1);
      }
    });
  }

  void _updateExtensionLensAperture(double value) {
    final lens = _selectedLens;
    if (lens == null) {
      return;
    }
    final focal = parseDouble(_extensionFocalMm.text) ?? lens.minFocalLengthMm;
    final minAtFocal = lens.minApertureAtFocal(focal);
    final aperture = value.clamp(minAtFocal, lens.maxAperture);

    setState(() {
      _extensionAperture.text = aperture.toStringAsFixed(1);
    });
  }

  void _setError(String message) {
    setState(() {
      _errorMessage = message;
      _standardResult = null;
      _macroResult = null;
      _macroResultLabel = null;
      _macroContextLabel = null;
      _macroCoverageLabel = null;
    });
  }

  void _calculate() {
    switch (_mode) {
      case FocusStackingSetupMode.standard:
        _method == FocusStackingMethod.refocusLens
            ? _calculateStandardRefocus()
            : _calculateStandardRail();
        return;
      case FocusStackingSetupMode.extensionTubes:
        _method == FocusStackingMethod.refocusLens
            ? _calculateExtensionRefocus()
            : _calculateExtensionRail();
        return;
      case FocusStackingSetupMode.reverseLens:
        _calculateReverse();
        return;
      case FocusStackingSetupMode.dualLens:
        _calculateDual();
        return;
    }
  }

  void _calculateStandardRefocus() {
    final focalMm = parseDouble(_standardFocalMm.text);
    final aperture = parseDouble(_standardAperture.text);
    final nearDistanceM = parseDouble(_standardNearDistanceM.text);
    final farDistanceM = parseDouble(_standardFarDistanceM.text);
    final overlapPercent = parseDouble(_overlapPercent.text);

    if (focalMm == null ||
        aperture == null ||
        nearDistanceM == null ||
        farDistanceM == null ||
        overlapPercent == null ||
        focalMm <= 0 ||
        aperture <= 0 ||
        nearDistanceM <= 0 ||
        farDistanceM <= 0) {
      _setError('Enter valid positive values.');
      return;
    }
    if (farDistanceM <= nearDistanceM) {
      _setError('The far subject point must be beyond the near point.');
      return;
    }
    if (overlapPercent < 0 || overlapPercent >= 95) {
      _setError('Overlap should stay between 0% and 95%.');
      return;
    }

    final lens = _selectedLens;
    if (lens != null) {
      final minAtFocal = lens.minApertureAtFocal(focalMm);
      if (aperture < minAtFocal || aperture > lens.maxAperture) {
        _setError(
          'Aperture must stay within f/${minAtFocal.toStringAsFixed(1)} and f/${lens.maxAperture.toStringAsFixed(1)} at ${focalMm.toStringAsFixed(0)}mm.',
        );
        return;
      }
    }

    final result = FocusStackingCalculator.plan(
      focalLengthMm: focalMm,
      aperture: aperture,
      cocM: _selectedSensor.cocMm / 1000,
      nearestSubjectDistanceM: nearDistanceM,
      farthestSubjectDistanceM: farDistanceM,
      overlapRatio: overlapPercent / 100,
    );

    if (lens != null &&
        result.firstFocusDistanceM != null &&
        result.firstFocusDistanceM! < lens.minFocusDistanceM) {
      _setError(
        '${lens.name} cannot focus close enough for that front subject point at the chosen focal length.',
      );
      return;
    }

    setState(() {
      _errorMessage = null;
      _standardResult = result;
      _macroResult = null;
      _macroResultLabel = null;
      _macroContextLabel = null;
      _macroCoverageLabel = null;
    });
  }

  void _calculateStandardRail() {
    final focalMm = parseDouble(_standardFocalMm.text);
    final aperture = parseDouble(_standardAperture.text);
    final nearDistanceM = parseDouble(_standardNearDistanceM.text);
    final farDistanceM = parseDouble(_standardFarDistanceM.text);
    final overlapPercent = parseDouble(_overlapPercent.text);

    if (focalMm == null ||
        aperture == null ||
        nearDistanceM == null ||
        farDistanceM == null ||
        overlapPercent == null ||
        focalMm <= 0 ||
        aperture <= 0 ||
        nearDistanceM <= 0 ||
        farDistanceM <= 0) {
      _setError('Enter valid positive values.');
      return;
    }
    if (farDistanceM <= nearDistanceM) {
      _setError('The far subject point must be beyond the near point.');
      return;
    }
    if (overlapPercent < 0 || overlapPercent >= 95) {
      _setError('Overlap should stay between 0% and 95%.');
      return;
    }

    final magnification =
        MacroCalculator.estimateMagnificationFromSensorDistance(
      focalLengthMm: focalMm,
      sensorToSubjectDistanceMm: ((nearDistanceM + farDistanceM) / 2) * 1000,
    );

    final macroPlan = MacroFocusStackingCalculator.plan(
      aperture: aperture,
      cocM: _selectedSensor.cocMm / 1000,
      magnification: magnification,
      subjectDepthM: farDistanceM - nearDistanceM,
      overlapRatio: overlapPercent / 100,
    );

    setState(() {
      _errorMessage = null;
      _standardResult = null;
      _macroResult = macroPlan;
      _macroResultLabel = 'Standard lens rail stack';
      _macroContextLabel =
          'Estimated at ${magnification.toStringAsFixed(2)}x around ${formatLengthMeters((nearDistanceM + farDistanceM) / 2)} subject distance.';
      _macroCoverageLabel =
          'Subject range ${formatLengthMeters(nearDistanceM)} to ${formatLengthMeters(farDistanceM)}';
    });
  }

  void _calculateExtensionRefocus() {
    final focalMm = parseDouble(_extensionFocalMm.text);
    final aperture = parseDouble(_extensionAperture.text);
    final minFocusDistanceM = parseDouble(_extensionMinFocusM.text);
    final extensionLengthMm = parseDouble(_extensionTubeMm.text);
    final nearDistanceM = parseDouble(_extensionNearDistanceM.text);
    final farDistanceM = parseDouble(_extensionFarDistanceM.text);
    final overlapPercent = parseDouble(_overlapPercent.text);

    if (focalMm == null ||
        aperture == null ||
        minFocusDistanceM == null ||
        extensionLengthMm == null ||
        nearDistanceM == null ||
        farDistanceM == null ||
        overlapPercent == null ||
        focalMm <= 0 ||
        aperture <= 0 ||
        minFocusDistanceM <= 0 ||
        extensionLengthMm < 0 ||
        nearDistanceM <= 0 ||
        farDistanceM <= 0) {
      _setError(
          'Enter valid values. Tube length may be zero, all other values must be positive.');
      return;
    }
    if (farDistanceM <= nearDistanceM) {
      _setError('The far subject point must be beyond the near point.');
      return;
    }
    if (overlapPercent < 0 || overlapPercent >= 95) {
      _setError('Overlap should stay between 0% and 95%.');
      return;
    }

    final extension = MacroCalculator.calculateExtensionTube(
      focalLengthMm: focalMm,
      aperture: aperture,
      cocM: _selectedSensor.cocMm / 1000,
      minimumFocusDistanceM: minFocusDistanceM,
      extensionLengthMm: extensionLengthMm,
    );

    final result = FocusStackingCalculator.plan(
      focalLengthMm: focalMm,
      aperture: aperture,
      cocM: _selectedSensor.cocMm / 1000,
      nearestSubjectDistanceM: nearDistanceM,
      farthestSubjectDistanceM: farDistanceM,
      overlapRatio: overlapPercent / 100,
    );

    setState(() {
      _errorMessage = null;
      _standardResult = result;
      _macroResult = null;
      _macroResultLabel = null;
      _macroContextLabel =
          'Extension is attached. Closest-focus magnification is about ${extension.maximumMagnification.toStringAsFixed(2)}x.';
      _macroCoverageLabel = null;
    });
  }

  void _calculateExtensionRail() {
    final focalMm = parseDouble(_extensionFocalMm.text);
    final aperture = parseDouble(_extensionAperture.text);
    final minFocusDistanceM = parseDouble(_extensionMinFocusM.text);
    final extensionLengthMm = parseDouble(_extensionTubeMm.text);
    final subjectDepthM = parseDouble(_extensionSubjectDepthM.text);
    final overlapPercent = parseDouble(_overlapPercent.text);

    if (focalMm == null ||
        aperture == null ||
        minFocusDistanceM == null ||
        extensionLengthMm == null ||
        subjectDepthM == null ||
        overlapPercent == null ||
        focalMm <= 0 ||
        aperture <= 0 ||
        minFocusDistanceM <= 0 ||
        extensionLengthMm < 0 ||
        subjectDepthM <= 0) {
      _setError(
          'Enter valid values. Tube length may be zero, all other values must be positive.');
      return;
    }
    if (overlapPercent < 0 || overlapPercent >= 95) {
      _setError('Overlap should stay between 0% and 95%.');
      return;
    }

    final extension = MacroCalculator.calculateExtensionTube(
      focalLengthMm: focalMm,
      aperture: aperture,
      cocM: _selectedSensor.cocMm / 1000,
      minimumFocusDistanceM: minFocusDistanceM,
      extensionLengthMm: extensionLengthMm,
    );

    final result = MacroFocusStackingCalculator.plan(
      aperture: aperture,
      cocM: _selectedSensor.cocMm / 1000,
      magnification: extension.maximumMagnification,
      subjectDepthM: subjectDepthM,
      overlapRatio: overlapPercent / 100,
    );

    setState(() {
      _errorMessage = null;
      _standardResult = null;
      _macroResult = result;
      _macroResultLabel = 'Extension tube stack';
      _macroContextLabel =
          'Planned at the closest-focus magnification ${extension.maximumMagnification.toStringAsFixed(2)}x. Closest focus is about ${formatLengthMeters(extension.closestFocusDistanceM)} from the sensor plane.';
      _macroCoverageLabel =
          'Planned subject depth ${formatLengthMeters(subjectDepthM)}';
    });
  }

  void _calculateReverse() {
    final focalMm = parseDouble(_reverseFocalMm.text);
    final aperture = parseDouble(_reverseAperture.text);
    final extraExtensionMm = parseDouble(_reverseExtraExtensionMm.text);
    final subjectDepthM = parseDouble(_reverseSubjectDepthM.text);
    final overlapPercent = parseDouble(_overlapPercent.text);
    final mount = _selectedMount;

    if (focalMm == null ||
        aperture == null ||
        extraExtensionMm == null ||
        subjectDepthM == null ||
        overlapPercent == null ||
        mount == null ||
        focalMm <= 0 ||
        aperture <= 0 ||
        extraExtensionMm < 0 ||
        subjectDepthM <= 0) {
      _setError('Select a mount and enter valid positive values.');
      return;
    }
    if (overlapPercent < 0 || overlapPercent >= 95) {
      _setError('Overlap should stay between 0% and 95%.');
      return;
    }

    final result = MacroCalculator.calculateReverseLens(
      focalLengthMm: focalMm,
      aperture: aperture,
      cocM: _selectedSensor.cocMm / 1000,
      extensionBehindLensMm: mount.registerDistanceMm + extraExtensionMm,
    );
    final macroPlan = MacroFocusStackingCalculator.plan(
      aperture: aperture,
      cocM: _selectedSensor.cocMm / 1000,
      magnification: result.magnification,
      subjectDepthM: subjectDepthM,
      overlapRatio: overlapPercent / 100,
    );

    setState(() {
      _errorMessage = null;
      _standardResult = null;
      _macroResult = macroPlan;
      _macroResultLabel = 'Reverse lens stack';
      _macroContextLabel =
          'Subject distance about ${formatLengthMeters(result.subjectDistanceFromLensPlaneM)} from the lens plane at ${result.magnification.toStringAsFixed(2)}x.';
      _macroCoverageLabel =
          'Planned subject depth ${formatLengthMeters(subjectDepthM)}';
    });
  }

  void _calculateDual() {
    final takingFocalMm = parseDouble(_dualTakingFocalMm.text);
    final aperture = parseDouble(_dualTakingAperture.text);
    final frontFocalMm = parseDouble(_dualFrontFocalMm.text);
    final subjectDepthM = parseDouble(_dualSubjectDepthM.text);
    final overlapPercent = parseDouble(_overlapPercent.text);

    if (takingFocalMm == null ||
        aperture == null ||
        frontFocalMm == null ||
        subjectDepthM == null ||
        overlapPercent == null ||
        takingFocalMm <= 0 ||
        aperture <= 0 ||
        frontFocalMm <= 0 ||
        subjectDepthM <= 0) {
      _setError('Enter valid positive values.');
      return;
    }
    if (overlapPercent < 0 || overlapPercent >= 95) {
      _setError('Overlap should stay between 0% and 95%.');
      return;
    }

    final result = MacroCalculator.calculateDualLensMacro(
      takingLensFocalLengthMm: takingFocalMm,
      takingLensAperture: aperture,
      cocM: _selectedSensor.cocMm / 1000,
      frontLensFocalLengthMm: frontFocalMm,
    );
    final macroPlan = MacroFocusStackingCalculator.plan(
      aperture: aperture,
      cocM: _selectedSensor.cocMm / 1000,
      magnification: result.magnification,
      subjectDepthM: subjectDepthM,
      overlapRatio: overlapPercent / 100,
    );

    setState(() {
      _errorMessage = null;
      _standardResult = null;
      _macroResult = macroPlan;
      _macroResultLabel = 'Dual lens macro stack';
      _macroContextLabel =
          'Working distance about ${formatLengthMeters(result.workingDistanceFromFrontLensM)} at ${result.magnification.toStringAsFixed(2)}x.';
      _macroCoverageLabel =
          'Planned subject depth ${formatLengthMeters(subjectDepthM)}';
    });
  }

  String _formatDistance(double valueM) => formatLengthMeters(valueM);

  Widget _buildModeSelector() {
    return SectionCard(
      title: 'Setup',
      children: [
        SegmentedButton<FocusStackingSetupMode>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: FocusStackingSetupMode.standard,
              label: Text('Standard'),
              icon: Icon(Icons.filter_center_focus),
            ),
            ButtonSegment(
              value: FocusStackingSetupMode.extensionTubes,
              label: Text('Extension'),
              icon: Icon(Icons.add_circle_outline),
            ),
            ButtonSegment(
              value: FocusStackingSetupMode.reverseLens,
              label: Text('Reverse'),
              icon: Icon(Icons.sync_alt),
            ),
            ButtonSegment(
              value: FocusStackingSetupMode.dualLens,
              label: Text('Dual Lens'),
              icon: Icon(Icons.join_inner),
            ),
          ],
          selected: {_mode},
          onSelectionChanged: (selection) {
            final nextMode = selection.first;
            setState(() {
              _mode = nextMode;
              _method = switch (nextMode) {
                FocusStackingSetupMode.reverseLens =>
                  FocusStackingMethod.moveCamera,
                FocusStackingSetupMode.dualLens =>
                  FocusStackingMethod.moveCamera,
                FocusStackingSetupMode.extensionTubes
                    when _method == FocusStackingMethod.moveCamera =>
                  FocusStackingMethod.moveCamera,
                _ => FocusStackingMethod.refocusLens,
              };
              _errorMessage = null;
              _standardResult = null;
              _macroResult = null;
              _macroResultLabel = null;
              _macroContextLabel = null;
              _macroCoverageLabel = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMethodSelector() {
    if (!_supportsRefocus) {
      return SectionCard(
        title: 'Method',
        children: const [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.straighten),
            title: Text('Move Camera / Rail'),
          ),
        ],
      );
    }

    return SectionCard(
      title: 'Method',
      children: [
        SegmentedButton<FocusStackingMethod>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: FocusStackingMethod.refocusLens,
              label: Text('Refocus Lens'),
              icon: Icon(Icons.tune),
            ),
            ButtonSegment(
              value: FocusStackingMethod.moveCamera,
              label: Text('Move Camera'),
              icon: Icon(Icons.straighten),
            ),
          ],
          selected: {_method},
          onSelectionChanged: (selection) {
            setState(() {
              _method = selection.first;
              _errorMessage = null;
              _standardResult = null;
              _macroResult = null;
              _macroResultLabel = null;
              _macroContextLabel = null;
              _macroCoverageLabel = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildLensPicker() {
    return SectionCard(
      title: 'Lens',
      children: [
        DropdownButtonFormField<int>(
          key: ValueKey('$_mode-$_selectedLensId'),
          initialValue: _selectedLensId,
          isExpanded: true,
          hint: const Text('Use a saved lens'),
          items: _lenses
              .map(
                (lens) => DropdownMenuItem<int>(
                  value: lens.id,
                  child: Text(
                    lens.displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          selectedItemBuilder: (context) => _lenses
              .map(
                (lens) => Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    lens.displayLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            final lensIndex = _lenses.indexWhere((lens) => lens.id == value);
            if (lensIndex >= 0) {
              _applyLensToCurrentMode(_lenses[lensIndex]);
            }
          },
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: _loadLenses,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh lenses'),
              ),
              if (_selectedLensId != null)
                TextButton.icon(
                  onPressed: _clearSelectedLens,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Enter manually'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSharedInputs({required List<Widget> children}) {
    return SectionCard(
      title: 'Inputs',
      children: [
        if (_availableSensors.length > 1) ...[
          DropdownButtonFormField<SensorPreset>(
            initialValue: _selectedSensor,
            decoration: const InputDecoration(
              labelText: 'Sensor format / circle of confusion',
            ),
            items: _availableSensors
                .map(
                  (sensor) => DropdownMenuItem<SensorPreset>(
                    value: sensor,
                    child: Text(sensor.displayName),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() => _selectedSensor = value);
            },
          ),
          const SizedBox(height: 12),
        ],
        ...children,
        NumField(
          controller: _overlapPercent,
          label: 'Overlap',
          suffix: '%',
          helpText:
              'How much one frame should overlap the next. Higher overlap is safer but increases frame count.',
        ),
        FilledButton(
          onPressed: _calculate,
          child: const Text('Plan Stack'),
        ),
      ],
    );
  }

  Widget _buildStandardInputs() {
    final lens = _selectedLens;
    final focalValue =
        parseDouble(_standardFocalMm.text) ?? (lens?.minFocalLengthMm ?? 100);
    final minApertureAtFocal = lens?.minApertureAtFocal(focalValue) ?? 1.0;
    final apertureValue =
        parseDouble(_standardAperture.text) ?? (lens?.minApertureWide ?? 5.6);

    return _buildSharedInputs(
      children: [
        if (lens == null) ...[
          NumField(
            controller: _standardFocalMm,
            label: 'Focal length',
            suffix: 'mm',
          ),
          NumField(
            controller: _standardAperture,
            label: 'Aperture',
            suffix: 'f',
          ),
        ] else ...[
          if (lens.isZoom)
            LensValueSlider(
              label: 'Focal length',
              minLabel: '${lens.minFocalLengthMm.toStringAsFixed(0)}mm',
              maxLabel: '${lens.maxFocalLengthMm.toStringAsFixed(0)}mm',
              min: lens.minFocalLengthMm,
              max: lens.maxFocalLengthMm,
              value: focalValue.clamp(
                lens.minFocalLengthMm,
                lens.maxFocalLengthMm,
              ),
              controller: _standardFocalMm,
              suffix: 'mm',
              onChanged: _updateStandardLensFocal,
            ),
          LensValueSlider(
            label: lens.variableAperture
                ? 'Aperture (changes with zoom)'
                : 'Aperture',
            minLabel: 'f/${minApertureAtFocal.toStringAsFixed(1)}',
            maxLabel: 'f/${lens.maxAperture.toStringAsFixed(1)}',
            min: minApertureAtFocal,
            max: lens.maxAperture,
            value: apertureValue.clamp(
              minApertureAtFocal,
              lens.maxAperture,
            ),
            controller: _standardAperture,
            suffix: 'f',
            onChanged: _updateStandardLensAperture,
          ),
        ],
        NumField(
          controller: _standardNearDistanceM,
          label: 'Nearest subject point',
          suffix: 'm',
          helpText:
              'The closest part of the subject that needs to be covered by the stack.',
        ),
        NumField(
          controller: _standardFarDistanceM,
          label: 'Farthest subject point',
          suffix: 'm',
          helpText:
              'The farthest part of the subject that needs to be covered by the stack.',
        ),
      ],
    );
  }

  Widget _buildExtensionInputs() {
    final lens = _selectedLens;
    final focalValue =
        parseDouble(_extensionFocalMm.text) ?? (lens?.minFocalLengthMm ?? 50);
    final minApertureAtFocal = lens?.minApertureAtFocal(focalValue) ?? 1.0;
    final apertureValue =
        parseDouble(_extensionAperture.text) ?? (lens?.minApertureWide ?? 2.8);

    return _buildSharedInputs(
      children: [
        if (lens == null) ...[
          NumField(
            controller: _extensionFocalMm,
            label: 'Focal length',
            suffix: 'mm',
          ),
          NumField(
            controller: _extensionAperture,
            label: 'Aperture',
            suffix: 'f',
          ),
        ] else ...[
          if (lens.isZoom)
            LensValueSlider(
              label: 'Focal length',
              minLabel: '${lens.minFocalLengthMm.toStringAsFixed(0)}mm',
              maxLabel: '${lens.maxFocalLengthMm.toStringAsFixed(0)}mm',
              min: lens.minFocalLengthMm,
              max: lens.maxFocalLengthMm,
              value: focalValue.clamp(
                lens.minFocalLengthMm,
                lens.maxFocalLengthMm,
              ),
              controller: _extensionFocalMm,
              suffix: 'mm',
              onChanged: _updateExtensionLensFocal,
            ),
          LensValueSlider(
            label: lens.variableAperture
                ? 'Aperture (changes with zoom)'
                : 'Aperture',
            minLabel: 'f/${minApertureAtFocal.toStringAsFixed(1)}',
            maxLabel: 'f/${lens.maxAperture.toStringAsFixed(1)}',
            min: minApertureAtFocal,
            max: lens.maxAperture,
            value: apertureValue.clamp(
              minApertureAtFocal,
              lens.maxAperture,
            ),
            controller: _extensionAperture,
            suffix: 'f',
            onChanged: _updateExtensionLensAperture,
          ),
        ],
        NumField(
          controller: _extensionMinFocusM,
          label: 'Lens minimum focus distance',
          suffix: 'm',
          helpText:
              'The closest focus distance of the lens by itself, before adding extension tubes.',
        ),
        NumField(
          controller: _extensionTubeMm,
          label: 'Total extension tube length',
          suffix: 'mm',
          helpText:
              'The combined extension of all tubes between camera and lens.',
        ),
        if (_method == FocusStackingMethod.refocusLens) ...[
          NumField(
            controller: _extensionNearDistanceM,
            label: 'Nearest subject point',
            suffix: 'm',
            helpText:
                'The closest part of the subject that needs to be covered by the stack.',
          ),
          NumField(
            controller: _extensionFarDistanceM,
            label: 'Farthest subject point',
            suffix: 'm',
            helpText:
                'The farthest part of the subject that needs to be covered by the stack.',
          ),
        ] else
          NumField(
            controller: _extensionSubjectDepthM,
            label: 'Subject depth to cover',
            suffix: 'm',
            helpText:
                'Total front-to-back subject thickness you want the rail move to cover.',
          ),
      ],
    );
  }

  Widget _buildReverseInputs() {
    return _buildSharedInputs(
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selectedMountId,
          decoration: const InputDecoration(labelText: 'Mount'),
          items: mountPresets
              .map(
                (mount) => DropdownMenuItem<String>(
                  value: mount.id,
                  child: Text(mount.label),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() => _selectedMountId = value);
          },
        ),
        const SizedBox(height: 12),
        NumField(
          controller: _reverseFocalMm,
          label: 'Reversed lens focal length',
          suffix: 'mm',
        ),
        NumField(
          controller: _reverseAperture,
          label: 'Aperture',
          suffix: 'f',
        ),
        NumField(
          controller: _reverseExtraExtensionMm,
          label: 'Extra extension',
          suffix: 'mm',
          helpText:
              'Additional spacing beyond the mount register distance, such as adapter or spacer thickness.',
        ),
        NumField(
          controller: _reverseSubjectDepthM,
          label: 'Subject depth to cover',
          suffix: 'm',
          helpText:
              'Total front-to-back subject thickness you want the rail move to cover.',
        ),
      ],
    );
  }

  Widget _buildDualInputs() {
    return _buildSharedInputs(
      children: [
        NumField(
          controller: _dualTakingFocalMm,
          label: 'Taking lens focal length',
          suffix: 'mm',
        ),
        NumField(
          controller: _dualTakingAperture,
          label: 'Taking lens aperture',
          suffix: 'f',
        ),
        NumField(
          controller: _dualFrontFocalMm,
          label: 'Reversed front-lens focal length',
          suffix: 'mm',
        ),
        NumField(
          controller: _dualSubjectDepthM,
          label: 'Subject depth to cover',
          suffix: 'm',
          helpText:
              'Total front-to-back subject thickness you want the rail move to cover.',
        ),
      ],
    );
  }

  Widget _buildStandardSummary(FocusStackingResult result) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        InfoMetricTile(label: 'Frames', value: '${result.frameCount}'),
        InfoMetricTile(
          label: 'First focus',
          value: _formatDistance(result.firstFocusDistanceM!),
          helpText: 'The first focus distance in the planned sequence.',
        ),
        InfoMetricTile(
          label: 'Last focus',
          value: _formatDistance(result.lastFocusDistanceM!),
          helpText: 'The last focus distance in the planned sequence.',
        ),
        InfoMetricTile(
          label: 'Average step',
          value: result.averageFocusStepM == null
              ? 'n/a'
              : _formatDistance(result.averageFocusStepM!),
          helpText:
              'Average change in focus distance between consecutive frames.',
        ),
        InfoMetricTile(
          label: 'Subject depth',
          value: _formatDistance(result.targetDepthM),
          helpText: 'The total subject range the plan is trying to cover.',
        ),
        InfoMetricTile(
          label: 'Overlap',
          value: '${(result.overlapRatio * 100).toStringAsFixed(0)}%',
          helpText:
              'How much neighboring frames overlap in coverage. More overlap is safer but slower.',
        ),
      ],
    );
  }

  Widget _buildMacroSummary(MacroFocusStackingResult result) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        InfoMetricTile(label: 'Frames', value: '${result.frameCount}'),
        InfoMetricTile(
          label: 'Magnification',
          value: '${result.planningMagnification.toStringAsFixed(2)}x',
          helpText:
              'The magnification used to estimate focus plane thickness and rail step.',
        ),
        InfoMetricTile(
          label: 'Focus plane',
          value: _formatDistance(result.focusPlaneThicknessM),
          helpText:
              'Estimated subject-side thickness covered in one frame at the planning magnification.',
        ),
        InfoMetricTile(
          label: 'Rail step',
          value: _formatDistance(result.recommendedRailStepM),
          helpText:
              'Recommended camera or rail movement between frames after the chosen overlap is applied.',
        ),
        InfoMetricTile(
          label: 'Subject depth',
          value: _formatDistance(result.subjectDepthM),
          helpText:
              'The total subject depth the rail move is planned to cover.',
        ),
        InfoMetricTile(
          label: 'Overlap',
          value: '${(result.overlapRatio * 100).toStringAsFixed(0)}%',
          helpText:
              'How much neighboring frames overlap in coverage. More overlap is safer but slower.',
        ),
      ],
    );
  }

  Widget _buildStandardShotList(FocusStackingResult result) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 360),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: result.shots.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _StandardShotRow(
          shot: result.shots[index],
          formatDistance: _formatDistance,
        ),
      ),
    );
  }

  Widget _buildMacroShotList(MacroFocusStackingResult result) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 360),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: result.shots.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _MacroShotRow(
          shot: result.shots[index],
          formatDistance: _formatDistance,
        ),
      ),
    );
  }

  Widget _buildOutput() {
    return SectionCard(
      title: 'Output',
      children: [
        if (_errorMessage != null)
          Text(
            _errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          )
        else if ((_mode == FocusStackingSetupMode.standard ||
                (_mode == FocusStackingSetupMode.extensionTubes &&
                    _method == FocusStackingMethod.refocusLens)) &&
            _standardResult == null)
          Text(
            'Enter a subject range to estimate focus positions and frame count.',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else if (!(_mode == FocusStackingSetupMode.standard ||
                (_mode == FocusStackingSetupMode.extensionTubes &&
                    _method == FocusStackingMethod.refocusLens)) &&
            _macroResult == null)
          Text(
            'Enter the setup values to estimate rail step and frame count.',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else if (_mode == FocusStackingSetupMode.standard ||
            (_mode == FocusStackingSetupMode.extensionTubes &&
                _method == FocusStackingMethod.refocusLens)) ...[
          _buildStandardSummary(_standardResult!),
          const SizedBox(height: 12),
          if (_standardResult!.frameLimitReached ||
              !_standardResult!.coversEntireRange)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'The planner hit its frame limit before covering the full range. Reduce overlap, stop down, or shorten the subject depth.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          _buildStandardShotList(_standardResult!),
        ] else ...[
          if (_macroResultLabel != null)
            Text(
              _macroResultLabel!,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          if (_macroContextLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              _macroContextLabel!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (_macroCoverageLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              _macroCoverageLabel!,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          _buildMacroSummary(_macroResult!),
          const SizedBox(height: 12),
          _buildMacroShotList(_macroResult!),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _buildModeSelector(),
          _buildMethodSelector(),
          if (_mode == FocusStackingSetupMode.standard ||
              _mode == FocusStackingSetupMode.extensionTubes)
            _buildLensPicker(),
          switch (_mode) {
            FocusStackingSetupMode.standard => _buildStandardInputs(),
            FocusStackingSetupMode.extensionTubes => _buildExtensionInputs(),
            FocusStackingSetupMode.reverseLens => _buildReverseInputs(),
            FocusStackingSetupMode.dualLens => _buildDualInputs(),
          },
          _buildOutput(),
        ],
      ),
    );
  }
}

class _StandardShotRow extends StatelessWidget {
  const _StandardShotRow({
    required this.shot,
    required this.formatDistance,
  });

  final FocusStackingShot shot;
  final String Function(double valueM) formatDistance;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = [
      'Focus ${formatDistance(shot.focusDistanceM)}',
      'Covers ${formatDistance(shot.nearLimitM)} to ${shot.farLimitM == null ? 'Infinity' : formatDistance(shot.farLimitM!)}',
      if (shot.stepFromPreviousM != null)
        'Step ${formatDistance(shot.stepFromPreviousM!)}',
    ].join(' | ');

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Text(
              '#${shot.index}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroShotRow extends StatelessWidget {
  const _MacroShotRow({
    required this.shot,
    required this.formatDistance,
  });

  final MacroFocusStackingShot shot;
  final String Function(double valueM) formatDistance;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subtitle = [
      'Target +${formatDistance(shot.focusOffsetM)}',
      'Covers +${formatDistance(shot.startOffsetM)} to +${formatDistance(shot.endOffsetM)}',
      if (shot.stepFromPreviousM != null)
        'Advance ${formatDistance(shot.stepFromPreviousM!)}',
    ].join(' | ');

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            child: Text(
              '#${shot.index}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
