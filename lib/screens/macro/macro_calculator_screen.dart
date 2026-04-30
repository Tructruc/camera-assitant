import 'package:camera_assistant/data/database/lens_database.dart';
import 'package:camera_assistant/domain/calculators/macro_calculator.dart';
import 'package:camera_assistant/domain/models/app_settings.dart';
import 'package:camera_assistant/domain/models/lens.dart';
import 'package:camera_assistant/domain/models/mount_preset.dart';
import 'package:camera_assistant/domain/models/sensor_preset.dart';
import 'package:camera_assistant/screens/focus_stacking/focus_stacking_planner_screen.dart';
import 'package:camera_assistant/shared/utils/formatters.dart';
import 'package:camera_assistant/shared/widgets/info_metric_tile.dart';
import 'package:camera_assistant/shared/widgets/lens_value_slider.dart';
import 'package:camera_assistant/shared/widgets/num_field.dart';
import 'package:camera_assistant/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';

enum MacroToolMode { extensionTubes, reverseLens, dualLens }

class MacroCalculatorScreen extends StatefulWidget {
  const MacroCalculatorScreen({
    super.key,
    required this.settings,
    this.initialMode = MacroToolMode.extensionTubes,
  });

  final AppSettings settings;
  final MacroToolMode initialMode;

  @override
  State<MacroCalculatorScreen> createState() => _MacroCalculatorScreenState();
}

class _MacroCalculatorScreenState extends State<MacroCalculatorScreen> {
  final _db = LensDatabase.instance;

  final _extensionFocalMm = TextEditingController(text: '50');
  final _extensionAperture = TextEditingController(text: '2.8');
  final _extensionMinFocusM = TextEditingController(text: '0.45');
  final _extensionTubeMm = TextEditingController(text: '25');

  final _reverseFocalMm = TextEditingController(text: '28');
  final _reverseAperture = TextEditingController(text: '2.8');
  final _reverseExtraExtensionMm = TextEditingController(text: '0');
  final _dualTakingFocalMm = TextEditingController(text: '100');
  final _dualTakingAperture = TextEditingController(text: '5.6');
  final _dualFrontFocalMm = TextEditingController(text: '50');

  List<Lens> _lenses = const [];
  int? _selectedLensId;
  int? _selectedDualTakingLensId;
  int? _selectedDualFrontLensId;
  String? _selectedMountId;
  late SensorPreset _selectedSensor;

  String? _extensionError;
  ExtensionTubeResult? _extensionResult;

  String? _reverseError;
  ReverseLensResult? _reverseResult;
  String? _dualError;
  DualLensMacroResult? _dualResult;

  List<SensorPreset> get _availableSensors =>
      resolveEnabledSensorPresets(widget.settings.enabledSensorIds);

  bool get _showExtensionTool =>
      widget.initialMode == MacroToolMode.extensionTubes;

  bool get _showDualLensTool => widget.initialMode == MacroToolMode.dualLens;

  @override
  void initState() {
    super.initState();
    _selectedSensor = _availableSensors.first;
    _loadLenses();
  }

  @override
  void dispose() {
    _extensionFocalMm.dispose();
    _extensionAperture.dispose();
    _extensionMinFocusM.dispose();
    _extensionTubeMm.dispose();
    _reverseFocalMm.dispose();
    _reverseAperture.dispose();
    _reverseExtraExtensionMm.dispose();
    _dualTakingFocalMm.dispose();
    _dualTakingAperture.dispose();
    _dualFrontFocalMm.dispose();
    super.dispose();
  }

  List<MountPreset> get _availableMounts {
    final enabled = widget.settings.enabledMountIds.toSet();
    final mounts = mountPresets
        .where((mount) => enabled.isEmpty || enabled.contains(mount.id))
        .toList();
    return mounts.isEmpty ? mountPresets.toList() : mounts;
  }

  MountPreset? get _selectedMount {
    for (final mount in _availableMounts) {
      if (mount.id == _selectedMountId) {
        return mount;
      }
    }
    return null;
  }

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

  Lens? get _selectedDualTakingLens {
    if (_selectedDualTakingLensId == null) {
      return null;
    }
    for (final lens in _lenses) {
      if (lens.id == _selectedDualTakingLensId) {
        return lens;
      }
    }
    return null;
  }

  Lens? get _selectedDualFrontLens {
    if (_selectedDualFrontLensId == null) {
      return null;
    }
    for (final lens in _lenses) {
      if (lens.id == _selectedDualFrontLensId) {
        return lens;
      }
    }
    return null;
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
      final mounts = _availableMounts;
      if (mounts.isNotEmpty &&
          !mounts.any((mount) => mount.id == _selectedMountId)) {
        _selectedMountId = mounts.first.id;
      }
    });
  }

  void _clearSelectedLens() {
    setState(() {
      _selectedLensId = null;
    });
  }

  void _clearSelectedDualLens({required bool frontLens}) {
    setState(() {
      if (frontLens) {
        _selectedDualFrontLensId = null;
      } else {
        _selectedDualTakingLensId = null;
      }
    });
  }

  void _applyLens(Lens lens) {
    if (_showExtensionTool) {
      _applyLensToExtension(lens);
    } else if (_showDualLensTool) {
      _applyLensToDualTaking(lens);
    } else {
      _applyLensToReverse(lens);
    }
  }

  void _applyLensToExtension(Lens lens) {
    final focal = lens.minFocalLengthMm;
    final aperture = lens.minApertureAtFocal(focal);
    setState(() {
      _selectedLensId = lens.id;
      _extensionFocalMm.text =
          focal.toStringAsFixed(focal.truncateToDouble() == focal ? 0 : 1);
      _extensionAperture.text = aperture.toStringAsFixed(1);
      _extensionMinFocusM.text = lens.minFocusDistanceM.toStringAsFixed(2);
    });
    _calculateExtension();
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
      _extensionFocalMm.text =
          focal.toStringAsFixed(focal.truncateToDouble() == focal ? 0 : 1);
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

  void _applyLensToReverse(Lens lens) {
    final focal = lens.minFocalLengthMm;
    final aperture = lens.minApertureAtFocal(focal);
    final mountPreset = resolveMountPreset(lens.mount);
    setState(() {
      _selectedLensId = lens.id;
      if (mountPreset != null &&
          _availableMounts.any((mount) => mount.id == mountPreset.id)) {
        _selectedMountId = mountPreset.id;
      }
      _reverseFocalMm.text =
          focal.toStringAsFixed(focal.truncateToDouble() == focal ? 0 : 1);
      _reverseAperture.text = aperture.toStringAsFixed(1);
    });
    _calculateReverse();
  }

  void _updateReverseLensFocal(double value) {
    final lens = _selectedLens;
    if (lens == null) {
      return;
    }
    final focal = value.clamp(lens.minFocalLengthMm, lens.maxFocalLengthMm);
    final minAtFocal = lens.minApertureAtFocal(focal);
    final currentAperture = parseDouble(_reverseAperture.text) ?? minAtFocal;

    setState(() {
      _reverseFocalMm.text =
          focal.toStringAsFixed(focal.truncateToDouble() == focal ? 0 : 1);
      if (currentAperture < minAtFocal) {
        _reverseAperture.text = minAtFocal.toStringAsFixed(1);
      }
    });
  }

  void _updateReverseLensAperture(double value) {
    final lens = _selectedLens;
    if (lens == null) {
      return;
    }
    final focal = parseDouble(_reverseFocalMm.text) ?? lens.minFocalLengthMm;
    final minAtFocal = lens.minApertureAtFocal(focal);
    final aperture = value.clamp(minAtFocal, lens.maxAperture);

    setState(() {
      _reverseAperture.text = aperture.toStringAsFixed(1);
    });
  }

  void _applyLensToDualTaking(Lens lens) {
    final focal = lens.maxFocalLengthMm;
    final aperture = lens.minApertureAtFocal(focal);
    setState(() {
      _selectedDualTakingLensId = lens.id;
      _dualTakingFocalMm.text =
          focal.toStringAsFixed(focal.truncateToDouble() == focal ? 0 : 1);
      _dualTakingAperture.text = aperture.toStringAsFixed(1);
    });
    _calculateDualLens();
  }

  void _updateDualTakingLensFocal(double value) {
    final lens = _selectedDualTakingLens;
    if (lens == null) {
      return;
    }
    final focal = value.clamp(lens.minFocalLengthMm, lens.maxFocalLengthMm);
    final minAtFocal = lens.minApertureAtFocal(focal);
    final currentAperture = parseDouble(_dualTakingAperture.text) ?? minAtFocal;

    setState(() {
      _dualTakingFocalMm.text =
          focal.toStringAsFixed(focal.truncateToDouble() == focal ? 0 : 1);
      if (currentAperture < minAtFocal) {
        _dualTakingAperture.text = minAtFocal.toStringAsFixed(1);
      }
    });
  }

  void _updateDualTakingLensAperture(double value) {
    final lens = _selectedDualTakingLens;
    if (lens == null) {
      return;
    }
    final focal = parseDouble(_dualTakingFocalMm.text) ?? lens.maxFocalLengthMm;
    final minAtFocal = lens.minApertureAtFocal(focal);
    final aperture = value.clamp(minAtFocal, lens.maxAperture);

    setState(() {
      _dualTakingAperture.text = aperture.toStringAsFixed(1);
    });
  }

  void _applyLensToDualFront(Lens lens) {
    final focal = lens.minFocalLengthMm;
    setState(() {
      _selectedDualFrontLensId = lens.id;
      _dualFrontFocalMm.text =
          focal.toStringAsFixed(focal.truncateToDouble() == focal ? 0 : 1);
    });
    _calculateDualLens();
  }

  void _updateDualFrontLensFocal(double value) {
    final lens = _selectedDualFrontLens;
    if (lens == null) {
      return;
    }
    final focal = value.clamp(lens.minFocalLengthMm, lens.maxFocalLengthMm);

    setState(() {
      _dualFrontFocalMm.text =
          focal.toStringAsFixed(focal.truncateToDouble() == focal ? 0 : 1);
    });
  }

  void _calculateExtension() {
    final focal = parseDouble(_extensionFocalMm.text);
    final aperture = parseDouble(_extensionAperture.text);
    final minFocusDistance = parseDouble(_extensionMinFocusM.text);
    final tubeLength = parseDouble(_extensionTubeMm.text);

    if (focal == null ||
        aperture == null ||
        minFocusDistance == null ||
        tubeLength == null ||
        focal <= 0 ||
        aperture <= 0 ||
        minFocusDistance <= 0 ||
        tubeLength < 0) {
      setState(() {
        _extensionError =
            'Enter valid values. Tube length may be zero, all other values must be positive.';
        _extensionResult = null;
      });
      return;
    }

    setState(() {
      _extensionError = null;
      _extensionResult = MacroCalculator.calculateExtensionTube(
        focalLengthMm: focal,
        aperture: aperture,
        cocM: _selectedSensor.cocMm / 1000,
        minimumFocusDistanceM: minFocusDistance,
        extensionLengthMm: tubeLength,
      );
    });
  }

  void _calculateReverse() {
    final focal = parseDouble(_reverseFocalMm.text);
    final aperture = parseDouble(_reverseAperture.text);
    final extraExtension = parseDouble(_reverseExtraExtensionMm.text);
    final mount = _selectedMount;

    if (focal == null ||
        aperture == null ||
        extraExtension == null ||
        mount == null ||
        focal <= 0 ||
        aperture <= 0 ||
        extraExtension < 0) {
      setState(() {
        _reverseError =
            'Select a mount and enter valid focal length, aperture, and extra extension values.';
        _reverseResult = null;
      });
      return;
    }

    final totalExtension = mount.registerDistanceMm + extraExtension;

    setState(() {
      _reverseError = null;
      _reverseResult = MacroCalculator.calculateReverseLens(
        focalLengthMm: focal,
        aperture: aperture,
        cocM: _selectedSensor.cocMm / 1000,
        extensionBehindLensMm: totalExtension,
      );
    });
  }

  void _calculateDualLens() {
    final takingFocal = parseDouble(_dualTakingFocalMm.text);
    final takingAperture = parseDouble(_dualTakingAperture.text);
    final frontFocal = parseDouble(_dualFrontFocalMm.text);

    if (takingFocal == null ||
        takingAperture == null ||
        frontFocal == null ||
        takingFocal <= 0 ||
        takingAperture <= 0 ||
        frontFocal <= 0) {
      setState(() {
        _dualError =
            'Enter valid taking-lens focal length, aperture, and reversed front-lens focal length values.';
        _dualResult = null;
      });
      return;
    }

    setState(() {
      _dualError = null;
      _dualResult = MacroCalculator.calculateDualLensMacro(
        takingLensFocalLengthMm: takingFocal,
        takingLensAperture: takingAperture,
        cocM: _selectedSensor.cocMm / 1000,
        frontLensFocalLengthMm: frontFocal,
      );
    });
  }

  String _formatMagnification(double value) => '${value.toStringAsFixed(2)}x';

  String _formatRatio(double value) {
    if (value <= 0) {
      return 'n/a';
    }
    if ((value - 1).abs() < 0.01) {
      return '1:1';
    }
    if (value > 1) {
      return '${value.toStringAsFixed(2)}:1';
    }
    return '1:${(1 / value).toStringAsFixed(1)}';
  }

  String _formatDistance(double valueM) {
    if (!valueM.isFinite) {
      return 'Infinity';
    }
    return '${valueM.toStringAsFixed(2)} m';
  }

  String _formatThickness(double valueM) {
    if (!valueM.isFinite) {
      return 'Infinity';
    }
    return formatLengthMeters(valueM);
  }

  String _formatStops(double value) => '+${value.toStringAsFixed(2)} stops';

  String _formatFactor(double value) => '${value.toStringAsFixed(2)}x';

  double _suggestMacroSubjectDepth(double thicknessM) {
    if (!thicknessM.isFinite || thicknessM <= 0) {
      return 0.005;
    }
    return (thicknessM * 5).clamp(0.001, 0.05).toDouble();
  }

  void _openExtensionFocusStacker() {
    final result = _extensionResult;
    if (result == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FocusStackingPlannerScreen(
          settings: widget.settings,
          initialPreset: FocusStackingPreset.extension(
            method: FocusStackingMethod.moveCamera,
            lensId: _selectedLensId,
            sensorCocMm: _selectedSensor.cocMm,
            focalMm: parseDouble(_extensionFocalMm.text),
            aperture: parseDouble(_extensionAperture.text),
            minimumFocusDistanceM: parseDouble(_extensionMinFocusM.text),
            extensionLengthMm: parseDouble(_extensionTubeMm.text),
            subjectDepthM: _suggestMacroSubjectDepth(
                result.focusPlaneThicknessAtClosestFocusM),
            overlapPercent: 30,
          ),
        ),
      ),
    );
  }

  void _openReverseFocusStacker() {
    final result = _reverseResult;
    if (result == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FocusStackingPlannerScreen(
          settings: widget.settings,
          initialPreset: FocusStackingPreset.reverse(
            method: FocusStackingMethod.moveCamera,
            sensorCocMm: _selectedSensor.cocMm,
            focalMm: parseDouble(_reverseFocalMm.text),
            aperture: parseDouble(_reverseAperture.text),
            mountId: _selectedMountId,
            extraExtensionMm: parseDouble(_reverseExtraExtensionMm.text),
            subjectDepthM:
                _suggestMacroSubjectDepth(result.focusPlaneThicknessM),
            overlapPercent: 30,
          ),
        ),
      ),
    );
  }

  void _openDualFocusStacker() {
    final result = _dualResult;
    if (result == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FocusStackingPlannerScreen(
          settings: widget.settings,
          initialPreset: FocusStackingPreset.dual(
            method: FocusStackingMethod.moveCamera,
            sensorCocMm: _selectedSensor.cocMm,
            takingLensFocalMm: parseDouble(_dualTakingFocalMm.text),
            aperture: parseDouble(_dualTakingAperture.text),
            frontLensFocalMm: parseDouble(_dualFrontFocalMm.text),
            subjectDepthM:
                _suggestMacroSubjectDepth(result.focusPlaneThicknessM),
            overlapPercent: 30,
          ),
        ),
      ),
    );
  }

  Widget _buildSensorSelector() {
    if (_availableSensors.length <= 1) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<SensorPreset>(
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
          if (_showExtensionTool) {
            _calculateExtension();
          } else if (_showDualLensTool) {
            _calculateDualLens();
          } else {
            _calculateReverse();
          }
        },
      ),
    );
  }

  Widget _buildLensPicker(
    BuildContext context, {
    required String hint,
  }) {
    return Column(
      children: [
        DropdownButtonFormField<int>(
          key: ValueKey(_selectedLensId),
          initialValue: _selectedLensId,
          isExpanded: true,
          hint: Text(hint),
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
              _applyLens(_lenses[lensIndex]);
            }
          },
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_lenses.isEmpty)
              Expanded(
                child: Text(
                  'No saved lenses yet.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              const Spacer(),
            if (_lenses.isEmpty) const SizedBox(width: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: _loadLenses,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
                if (_selectedLensId != null)
                  TextButton.icon(
                    onPressed: _clearSelectedLens,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Enter manually'),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildDualLensPicker(
    BuildContext context, {
    required int? selectedLensId,
    required bool isFrontLens,
    required String hint,
    required ValueChanged<Lens> onSelected,
  }) {
    return Column(
      children: [
        DropdownButtonFormField<int>(
          key: ValueKey(selectedLensId),
          initialValue: selectedLensId,
          isExpanded: true,
          hint: Text(hint),
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
          onChanged: (value) {
            if (value == null) {
              return;
            }
            final lensIndex = _lenses.indexWhere((lens) => lens.id == value);
            if (lensIndex >= 0) {
              onSelected(_lenses[lensIndex]);
            }
          },
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_lenses.isEmpty)
              Expanded(
                child: Text(
                  'No saved lenses yet.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              const Spacer(),
            if (_lenses.isEmpty) const SizedBox(width: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: _loadLenses,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
                if (selectedLensId != null)
                  TextButton.icon(
                    onPressed: () =>
                        _clearSelectedDualLens(frontLens: isFrontLens),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Enter manually'),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildExtensionTool(BuildContext context) {
    final lens = _selectedLens;
    final focalValue =
        parseDouble(_extensionFocalMm.text) ?? (lens?.minFocalLengthMm ?? 50);
    final minApertureAtFocal = lens?.minApertureAtFocal(focalValue) ?? 1.0;
    final apertureValue =
        parseDouble(_extensionAperture.text) ?? (lens?.minApertureWide ?? 2.8);

    return Column(
      children: [
        SectionCard(
          title: 'Inputs',
          children: [
            _buildLensPicker(
              context,
              hint: 'Use a saved lens',
            ),
            _buildSensorSelector(),
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
            FilledButton(
              onPressed: _calculateExtension,
              child: const Text('Calculate Extension'),
            ),
          ],
        ),
        SectionCard(
          title: 'Output',
          children: [
            if (_extensionError != null)
              Text(
                _extensionError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else if (_extensionResult == null)
              Text(
                'No result',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  InfoMetricTile(
                    label: 'Native close focus',
                    value:
                        '${_formatMagnification(_extensionResult!.nativeMaximumMagnification)} | ${_formatRatio(_extensionResult!.nativeMaximumMagnification)}',
                    helpText:
                        'The lens maximum magnification without any extension tubes attached.',
                  ),
                  InfoMetricTile(
                    label: 'Tube gain',
                    value: _formatMagnification(
                        _extensionResult!.addedMagnification),
                    helpText:
                        'The extra magnification added by the extension tubes alone.',
                  ),
                  InfoMetricTile(
                    label: 'Magnification range',
                    value:
                        '${_formatMagnification(_extensionResult!.minimumMagnification)} to ${_formatMagnification(_extensionResult!.maximumMagnification)}',
                  ),
                  InfoMetricTile(
                    label: 'Macro ratio range',
                    value:
                        '${_formatRatio(_extensionResult!.minimumMagnification)} to ${_formatRatio(_extensionResult!.maximumMagnification)}',
                  ),
                  InfoMetricTile(
                    label: 'Closest focus',
                    value: _formatDistance(
                        _extensionResult!.closestFocusDistanceM),
                  ),
                  InfoMetricTile(
                    label: 'Farthest focus',
                    value: _formatDistance(
                        _extensionResult!.farthestFocusDistanceM),
                  ),
                  InfoMetricTile(
                    label: 'Effective aperture',
                    value:
                        'f/${_extensionResult!.effectiveApertureAtFarthestFocus.toStringAsFixed(1)} to f/${_extensionResult!.effectiveApertureAtClosestFocus.toStringAsFixed(1)}',
                    helpText:
                        'The effective f-number at the subject, including magnification. It is darker than the marked lens aperture.',
                  ),
                  InfoMetricTile(
                    label: 'Light loss',
                    value:
                        '${_formatStops(_extensionResult!.lightLossStopsAtFarthestFocus)} to ${_formatStops(_extensionResult!.lightLossStopsAtClosestFocus)}',
                    helpText:
                        'Exposure loss caused by working at higher magnification.',
                  ),
                  InfoMetricTile(
                    label: 'Exposure factor',
                    value:
                        '${_formatFactor(_extensionResult!.exposureFactorAtFarthestFocus)} to ${_formatFactor(_extensionResult!.exposureFactorAtClosestFocus)}',
                    helpText:
                        'Exposure multiplier needed to compensate for the light loss at macro magnification.',
                  ),
                  InfoMetricTile(
                    label: 'Focus plane thickness',
                    value:
                        '${_formatThickness(_extensionResult!.focusPlaneThicknessAtFarthestFocusM)} to ${_formatThickness(_extensionResult!.focusPlaneThicknessAtClosestFocusM)}',
                    helpText:
                        'Estimated subject-side thickness that appears sharp at the current settings.',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: _openExtensionFocusStacker,
                  icon: const Icon(Icons.layers_outlined),
                  label: const Text('Open in Focus Stacking'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildReverseTool(BuildContext context) {
    final lens = _selectedLens;
    final focalValue =
        parseDouble(_reverseFocalMm.text) ?? (lens?.minFocalLengthMm ?? 28);
    final minApertureAtFocal = lens?.minApertureAtFocal(focalValue) ?? 1.0;
    final apertureValue =
        parseDouble(_reverseAperture.text) ?? (lens?.minApertureWide ?? 2.8);

    return Column(
      children: [
        SectionCard(
          title: 'Inputs',
          children: [
            _buildLensPicker(
              context,
              hint: 'Use a saved lens',
            ),
            _buildSensorSelector(),
            DropdownButtonFormField<String>(
              initialValue: _selectedMountId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Mount'),
              items: _availableMounts
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
                _calculateReverse();
              },
            ),
            const SizedBox(height: 12),
            if (lens == null) ...[
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
            ] else ...[
              if (lens.isZoom)
                LensValueSlider(
                  label: 'Reversed lens focal length',
                  minLabel: '${lens.minFocalLengthMm.toStringAsFixed(0)}mm',
                  maxLabel: '${lens.maxFocalLengthMm.toStringAsFixed(0)}mm',
                  min: lens.minFocalLengthMm,
                  max: lens.maxFocalLengthMm,
                  value: focalValue.clamp(
                    lens.minFocalLengthMm,
                    lens.maxFocalLengthMm,
                  ),
                  controller: _reverseFocalMm,
                  suffix: 'mm',
                  onChanged: _updateReverseLensFocal,
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
                controller: _reverseAperture,
                suffix: 'f',
                onChanged: _updateReverseLensAperture,
              ),
            ],
            NumField(
              controller: _reverseExtraExtensionMm,
              label: 'Extra extension',
              suffix: 'mm',
              helpText:
                  'Additional spacing beyond the mount register distance, such as adapter or spacer thickness.',
            ),
            if (_selectedMountId != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Mount register distance: ${_selectedMount!.registerDistanceMm.toStringAsFixed(1)} mm',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            FilledButton(
              onPressed: _calculateReverse,
              child: const Text('Calculate Reverse Lens'),
            ),
          ],
        ),
        SectionCard(
          title: 'Output',
          children: [
            if (_reverseError != null)
              Text(
                _reverseError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else if (_reverseResult == null)
              Text(
                'No result',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  InfoMetricTile(
                    label: 'Magnification',
                    value:
                        '${_formatMagnification(_reverseResult!.magnification)} | ${_formatRatio(_reverseResult!.magnification)}',
                  ),
                  InfoMetricTile(
                    label: 'Effective aperture',
                    value:
                        'f/${_reverseResult!.effectiveAperture.toStringAsFixed(1)}',
                    helpText:
                        'The effective f-number at the subject, including magnification. It is darker than the marked lens aperture.',
                  ),
                  InfoMetricTile(
                    label: 'Light loss',
                    value: _formatStops(_reverseResult!.lightLossStops),
                    helpText:
                        'Exposure loss caused by working at higher magnification.',
                  ),
                  InfoMetricTile(
                    label: 'Exposure factor',
                    value: _formatFactor(_reverseResult!.exposureFactor),
                    helpText:
                        'Exposure multiplier needed to compensate for the light loss at macro magnification.',
                  ),
                  InfoMetricTile(
                    label: 'Total extension',
                    value:
                        '${(_selectedMount!.registerDistanceMm + (parseDouble(_reverseExtraExtensionMm.text) ?? 0)).toStringAsFixed(1)} mm',
                    helpText:
                        'Mount register distance plus any extra spacer thickness used in the reversed setup.',
                  ),
                  InfoMetricTile(
                    label: 'Subject distance',
                    value: _formatDistance(
                      _reverseResult!.subjectDistanceFromLensPlaneM,
                    ),
                    helpText:
                        'Approximate distance from the front lens plane to the subject.',
                  ),
                  InfoMetricTile(
                    label: 'Sensor-to-subject',
                    value: _formatDistance(
                      _reverseResult!.subjectDistanceFromSensorPlaneM,
                    ),
                    helpText:
                        'Approximate distance from the sensor plane to the subject.',
                  ),
                  InfoMetricTile(
                    label: 'Focus plane thickness',
                    value: _formatThickness(
                      _reverseResult!.focusPlaneThicknessM,
                    ),
                    helpText:
                        'Estimated subject-side thickness that appears sharp at the current settings.',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: _openReverseFocusStacker,
                  icon: const Icon(Icons.layers_outlined),
                  label: const Text('Open in Focus Stacking'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDualLensTool(BuildContext context) {
    final takingLens = _selectedDualTakingLens;
    final takingFocalValue = parseDouble(_dualTakingFocalMm.text) ??
        (takingLens?.maxFocalLengthMm ?? 100);
    final takingMinApertureAtFocal =
        takingLens?.minApertureAtFocal(takingFocalValue) ?? 1.0;
    final takingApertureValue = parseDouble(_dualTakingAperture.text) ??
        (takingLens?.minApertureWide ?? 5.6);
    final frontLens = _selectedDualFrontLens;
    final frontFocalValue = parseDouble(_dualFrontFocalMm.text) ??
        (frontLens?.minFocalLengthMm ?? 50);

    return Column(
      children: [
        SectionCard(
          title: 'Inputs',
          children: [
            _buildDualLensPicker(
              context,
              selectedLensId: _selectedDualTakingLensId,
              isFrontLens: false,
              hint: 'Pick the taking lens',
              onSelected: _applyLensToDualTaking,
            ),
            if (takingLens == null) ...[
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
            ] else ...[
              if (takingLens.isZoom)
                LensValueSlider(
                  label: 'Taking lens focal length',
                  minLabel:
                      '${takingLens.minFocalLengthMm.toStringAsFixed(0)}mm',
                  maxLabel:
                      '${takingLens.maxFocalLengthMm.toStringAsFixed(0)}mm',
                  min: takingLens.minFocalLengthMm,
                  max: takingLens.maxFocalLengthMm,
                  value: takingFocalValue.clamp(
                    takingLens.minFocalLengthMm,
                    takingLens.maxFocalLengthMm,
                  ),
                  controller: _dualTakingFocalMm,
                  suffix: 'mm',
                  onChanged: _updateDualTakingLensFocal,
                ),
              LensValueSlider(
                label: takingLens.variableAperture
                    ? 'Taking lens aperture (changes with zoom)'
                    : 'Taking lens aperture',
                minLabel: 'f/${takingMinApertureAtFocal.toStringAsFixed(1)}',
                maxLabel: 'f/${takingLens.maxAperture.toStringAsFixed(1)}',
                min: takingMinApertureAtFocal,
                max: takingLens.maxAperture,
                value: takingApertureValue.clamp(
                  takingMinApertureAtFocal,
                  takingLens.maxAperture,
                ),
                controller: _dualTakingAperture,
                suffix: 'f',
                onChanged: _updateDualTakingLensAperture,
              ),
            ],
            _buildSensorSelector(),
            const SizedBox(height: 8),
            _buildDualLensPicker(
              context,
              selectedLensId: _selectedDualFrontLensId,
              isFrontLens: true,
              hint: 'Pick the reversed front lens',
              onSelected: _applyLensToDualFront,
            ),
            if (frontLens == null)
              NumField(
                controller: _dualFrontFocalMm,
                label: 'Reversed front-lens focal length',
                suffix: 'mm',
              )
            else if (frontLens.isZoom)
              LensValueSlider(
                label: 'Reversed front-lens focal length',
                minLabel: '${frontLens.minFocalLengthMm.toStringAsFixed(0)}mm',
                maxLabel: '${frontLens.maxFocalLengthMm.toStringAsFixed(0)}mm',
                min: frontLens.minFocalLengthMm,
                max: frontLens.maxFocalLengthMm,
                value: frontFocalValue.clamp(
                  frontLens.minFocalLengthMm,
                  frontLens.maxFocalLengthMm,
                ),
                controller: _dualFrontFocalMm,
                suffix: 'mm',
                onChanged: _updateDualFrontLensFocal,
              ),
            FilledButton(
              onPressed: _calculateDualLens,
              child: const Text('Calculate Dual Lens Macro'),
            ),
          ],
        ),
        SectionCard(
          title: 'Output',
          children: [
            if (_dualError != null)
              Text(
                _dualError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )
            else if (_dualResult == null)
              Text(
                'No result',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  InfoMetricTile(
                    label: 'Magnification',
                    value:
                        '${_formatMagnification(_dualResult!.magnification)} | ${_formatRatio(_dualResult!.magnification)}',
                  ),
                  InfoMetricTile(
                    label: 'Effective aperture',
                    value:
                        'f/${_dualResult!.effectiveAperture.toStringAsFixed(1)}',
                    helpText:
                        'The effective f-number at the subject, including magnification. It is darker than the marked lens aperture.',
                  ),
                  InfoMetricTile(
                    label: 'Light loss',
                    value: _formatStops(_dualResult!.lightLossStops),
                    helpText:
                        'Exposure loss caused by working at higher magnification.',
                  ),
                  InfoMetricTile(
                    label: 'Exposure factor',
                    value: _formatFactor(_dualResult!.exposureFactor),
                    helpText:
                        'Exposure multiplier needed to compensate for the light loss at macro magnification.',
                  ),
                  InfoMetricTile(
                    label: 'Approx. working distance',
                    value: _formatDistance(
                      _dualResult!.workingDistanceFromFrontLensM,
                    ),
                    helpText:
                        'Approximate distance from the front reversed lens to the subject.',
                  ),
                  InfoMetricTile(
                    label: 'Focus plane thickness',
                    value: _formatThickness(
                      _dualResult!.focusPlaneThicknessM,
                    ),
                    helpText:
                        'Estimated subject-side thickness that appears sharp at the current settings.',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: _openDualFocusStacker,
                  icon: const Icon(Icons.layers_outlined),
                  label: const Text('Open in Focus Stacking'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This model assumes both lenses are coupled and focused at infinity. Real spacing and adapter thickness can shift the result slightly.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: _showExtensionTool
          ? _buildExtensionTool(context)
          : _showDualLensTool
              ? _buildDualLensTool(context)
              : _buildReverseTool(context),
    );
  }
}
